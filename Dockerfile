FROM debian:stable-slim AS env_base
# Pre-reqs
RUN apt-get update && apt-get install --no-install-recommends -y \
    git vim build-essential python3-dev python3-pip

RUN apt-get install -y python3-full python3-venv

# RUN pip3 install virtualenv
# RUN virtualenv /venv
# Credit, Itamar Turner-Trauring: https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN /venv/bin/pip3 install --upgrade pip setuptools

FROM env_base AS app_base
### DEVELOPERS/ADVANCED USERS ###
# Clone llama2-webui
RUN git clone --branch cpu https://github.com/BobCN2017/llama2-webui /src

# Copy source to app
RUN cp -ar /src /app
# Install llama2-webui
RUN --mount=type=cache,target=/root/.cache/pip /venv/bin/pip3 install -r /app/requirements.txt

RUN CMAKE_ARGS="-DLLAMA_CUBLAS=1 -DLLAMA_AVX=OFF -DLLAMA_AVX2=OFF -DLLAMA_F16C=OFF -DLLAMA_FMA=OFF" FORCE_CMAKE=1 pip install --upgrade --force-reinstall llama-cpp-python --no-cache-dir

FROM app_base AS base
# download models
RUN mkdir /app/default_models
COPY  llama-2-7b-chat.ggmlv3.q4_0.bin /app/default_models

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