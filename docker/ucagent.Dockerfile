FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      cmake \
      g++ \
      git \
      make \
      ninja-build \
      python3 \
      python3-pip \
      python3-venv \
      verilator \
      yosys \
      z3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --depth 1 https://github.com/XS-MLVP/UCAgent.git && \
    git clone --depth 1 https://github.com/XS-MLVP/Example-NutShellCache.git && \
    git clone --depth 1 https://github.com/XS-MLVP/picker.git

RUN python3 -m venv /opt/ucagent-venv && \
    /opt/ucagent-venv/bin/pip install --upgrade pip && \
    /opt/ucagent-venv/bin/pip install -r /opt/UCAgent/requirements.txt && \
    /opt/ucagent-venv/bin/pip install -e /opt/UCAgent -e /opt/picker pytest

ENV PATH="/opt/ucagent-venv/bin:${PATH}"
ENV PYTHONPATH="/opt/UCAgent:${PYTHONPATH}"

WORKDIR /work
CMD ["bash"]
