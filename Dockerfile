FROM openroad/ubuntu22.04-dev AS env_base
# Pre-reqs
RUN apt-get update && apt-get install --no-install-recommends -y \
    git vim build-essential python3-dev python3-pip

RUN pip3 install --upgrade pip setuptools

FROM env_base AS app_base
### DEVELOPERS/ADVANCED USERS ###
# Clone llama2-webui
RUN git clone --branch cpu https://github.com/BobCN2017/llama2-webui /src

# Copy source to app
RUN cp -ar /src /app
# Install llama2-webui
RUN --mount=type=cache,target=/root/.cache/pip pip3 install -r /app/requirements.txt


FROM app_base AS base
# download models
RUN python3 /app/llama2_wrapper/download/__main__.py\
    --repo_id TheBloke/Llama-2-7B-Chat-GGML --filename llama-2-7b-chat.ggmlv3.q4_0.bin --save_dir /app/default_models


FROM base as base_ready
RUN rm -rf /root/.cache/pip/*

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

RUN echo "change.........."
# Copy and enable all scripts
COPY ./scripts /scripts
RUN chmod +x /scripts/*
RUN cd /src
RUN git pull
RUN cp -ar /src /app

# Run
ENTRYPOINT ["/scripts/docker-entrypoint.sh"]

FROM base_ready AS default
RUN echo "DEFAULT" >> /variant.txt
ENV CLI_ARGS=""
CMD python3 /app/app.py ${CLI_ARGS}