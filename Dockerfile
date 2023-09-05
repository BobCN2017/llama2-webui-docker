FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS env_base
# Pre-reqs
RUN apt-get update && apt-get install -y software-properties-common wget && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install --no-install-recommends -y \
    git vim build-essential python3.10-dev python3.10-venv python3.10-distutils && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3.10 get-pip.py

# Instantiate venv and pre-activate
RUN pip3 install virtualenv
RUN virtualenv /venv
# Credit, Itamar Turner-Trauring: https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip3 install --upgrade pip setuptools

RUN --mount=type=cache,target=/var/cache/pip pip3 install torch==2.0.1+cu118 --extra-index-url https://download.pytorch.org/whl/cu118

FROM env_base AS app_base 
# Clone llama2-webui
RUN git clone https://github.com/BobCN2017/llama2-webui /src

# Copy source to app
RUN cp -ar /src /app
# Install llama2-webui
RUN --mount=type=cache,target=/root/.cache/pip pip3 install -r /app/requirements.txt

RUN git clone https://github.com/TimDettmers/bitsandbytes.git
RUN cd bitsandbytes && CUDA_VERSION=118 make cuda11x && python setup.py install

FROM python:3.10.9-slim as base
RUN apt-get update && apt-get install --no-install-recommends -y \
    git vim python3-venv
ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1

RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update && \
  # we need those
  apt-get install -y git jq moreutils

# Copy app and src
COPY --from=app_base /app /app
COPY --from=app_base /src /src
# Copy and activate venv
COPY --from=app_base /venv /venv
ENV VIRTUAL_ENV=/venv
RUN rm -rf /venv/bin/python && ln -s /usr/local/bin/python /venv/bin/python
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

# download models
RUN mkdir -p /app/default_models/Llama-2-7b-Chat-GPTQ
COPY /Llama-2-7b-Chat-GPTQ /app/default_models/Llama-2-7b-Chat-GPTQ 

FROM base as base_ready
RUN rm -rf /root/.cache/pip/*
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

FROM base_ready AS default
RUN echo "DEFAULT" >> /variant.txt
ENV CLI_ARGS=""
CMD python3 /app/app.py ${CLI_ARGS}