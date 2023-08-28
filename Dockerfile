FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS env_base
# Pre-reqs
RUN apt-get update && apt-get install --no-install-recommends -y \
    git vim build-essential python3-dev python3-venv python3-pip
# Instantiate venv and pre-activate
RUN pip3 install virtualenv
RUN virtualenv /venv
# Credit, Itamar Turner-Trauring: https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip3 install --upgrade pip setuptools

FROM env_base AS app_base 
### DEVELOPERS/ADVANCED USERS ###
# Clone oobabooga/text-generation-webui
RUN git clone https://github.com/BobCN2017/llama2-webui /src

# Copy source to app
RUN cp -ar /src /app
# Install oobabooga/text-generation-webui
RUN --mount=type=cache,target=/root/.cache/pip pip3 install -r /app/requirements.txt

# download models
RUN python /app/llama2_wrapper/download/__main__.py\
    --repo_id TheBloke/Llama-2-7B-Chat-GGML --filename llama-2-7b-chat.ggmlv3.q4_0.bin --save_dir /app/default_models
RUN  python /app/llama2_wrapper/download/__main__.py --repo_id TheBloke/Llama-2-7B-Chat-GPTQ --save_dir /app/default_models 

RUN apt-get update && apt-get install -y rsync

FROM app_base as base
# Finalise app setup
WORKDIR /app
EXPOSE 7860
EXPOSE 5000
EXPOSE 5005
# Required for Python print statements to appear in logs
ENV PYTHONUNBUFFERED=1
# Force variant layers to sync cache by setting --build-arg BUILD_DATE
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
RUN echo "$BUILD_DATE" > /build_date.txt


# Copy and enable all scripts
COPY ./scripts /scripts
RUN chmod +x /scripts/*
RUN cd /src
RUN git pull
RUN cp -ar /src /app

# Run
ENTRYPOINT ["/scripts/docker-entrypoint.sh"]

FROM base AS default
RUN echo "DEFAULT" >> /variant.txt
ENV CLI_ARGS=""
CMD python3 /app/app.py ${CLI_ARGS}