FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY docker/retry-git-clone.sh /usr/local/bin/retry-git-clone
COPY docker/retry-curl.sh /usr/local/bin/retry-curl
RUN chmod +x /usr/local/bin/retry-git-clone /usr/local/bin/retry-curl

RUN for attempt in 1 2 3 4 5; do \
      rm -rf /var/lib/apt/lists/*; \
      echo "[apt] attempt ${attempt}/5"; \
      if apt-get update -o Acquire::Retries=5 && \
         apt-get install -y --no-install-recommends \
          bash \
          ca-certificates \
          cmake \
          curl \
          file \
          g++ \
          gcc \
          git \
          gosu \
          gtkwave \
          iverilog \
          jq \
          libffi-dev \
          lcov \
          make \
          ninja-build \
          openjdk-17-jre-headless \
          pkg-config \
          python3 \
          python3-dev \
          python3-pip \
          python3-venv \
          rsync \
          swig \
          verilator \
          yosys \
          z3; then \
        rm -rf /var/lib/apt/lists/*; \
        exit 0; \
      fi; \
      sleep 10; \
    done; \
    exit 1

RUN retry-git-clone https://github.com/YosysHQ/sby.git /tmp/sby --depth 1 && \
    make -C /tmp/sby install PREFIX=/usr/local && \
    rm -rf /tmp/sby

WORKDIR /opt/toolchain
RUN retry-git-clone https://github.com/XS-MLVP/UCAgent.git UCAgent --depth 1 && \
    retry-git-clone https://github.com/XS-MLVP/Example-NutShellCache.git Example-NutShellCache --depth 1 && \
    retry-git-clone https://github.com/XS-MLVP/picker.git picker --depth 1

RUN make -C /opt/toolchain/picker init && \
    make -C /opt/toolchain/picker BUILD_XSPCOMM_SWIG=python -j"$(nproc)" && \
    make -C /opt/toolchain/picker BUILD_XSPCOMM_SWIG=python install

RUN mkdir -p /opt/toolchain/bin && \
    for version in 0.9.12 0.11.12; do \
      retry-curl -L --fail \
        "https://github.com/com-lihaoyi/mill/releases/download/${version}/${version}" \
        -o "/opt/toolchain/bin/mill-${version}"; \
      chmod +x "/opt/toolchain/bin/mill-${version}"; \
    done

RUN python3 -m venv /opt/ucagent-venv && \
    /opt/ucagent-venv/bin/pip install --upgrade pip wheel setuptools && \
    /opt/ucagent-venv/bin/pip install -r /opt/toolchain/UCAgent/requirements.txt && \
    /opt/ucagent-venv/bin/pip install --no-deps -e /opt/toolchain/UCAgent

COPY docker/conda-shim /usr/local/bin/conda
COPY docker/repro-entrypoint.sh /usr/local/bin/ucagent-formal-entrypoint
RUN chmod +x /usr/local/bin/conda /usr/local/bin/ucagent-formal-entrypoint

ENV PATH="/opt/ucagent-venv/bin:/opt/toolchain/bin:${PATH}"
ENV PYTHONPATH="/opt/toolchain/UCAgent:/usr/local/share/picker/python:/usr/local/lib/python3.12/site-packages:/usr/local/lib/python3.12/dist-packages"
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV NUTSHELL_CACHE_VERIFY_DOCKER=1

WORKDIR /work
ENTRYPOINT ["ucagent-formal-entrypoint"]
CMD ["bash"]
