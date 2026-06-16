FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      make \
      python3 \
      yosys \
      z3 && \
    git clone --depth 1 https://github.com/YosysHQ/sby.git /tmp/sby && \
    make -C /tmp/sby install PREFIX=/usr/local && \
    rm -rf /tmp/sby /var/lib/apt/lists/*

WORKDIR /work
CMD ["bash"]
