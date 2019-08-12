FROM ingomuellernet/arrow:0.14 as arrow-builder
FROM ingomuellernet/aws-sdk-cpp:1.7.138 as aws-sdk-cpp-builder
FROM ingomuellernet/boost:1.70.0 as boost-builder
FROM ingomuellernet/cppcheck:1.80-1.88 as cppcheck-builder
FROM ingomuellernet/llvmgold:7.0.1 as gold-builder

FROM ubuntu:bionic
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

# Basics
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        git \
        python3-pip \
        wget \
        xz-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clang+LLVM
RUN mkdir /opt/clang+llvm-7.0.1/ && \
    cd /opt/clang+llvm-7.0.1/ && \
    wget --progress=dot:giga http://releases.llvm.org/7.0.1/clang+llvm-7.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz -O - \
         | tar -x -I xz --strip-components=1 && \
    for file in bin/*; \
    do \
        ln -s $PWD/$file /usr/bin/$(basename $file)-7.0; \
    done && \
    cp /opt/clang+llvm-7.0.1/lib/libomp.so /opt/clang+llvm-7.0.1/lib/libomp.so.5

ENV CMAKE_PREFIX_PATH $CMAKE_PREFIX_PATH:/opt/clang+llvm-7.0.1

# Copy llvm gold plugin over from builder
COPY --from=gold-builder /tmp/llvm-7.0.1.src/build/lib/LLVMgold.so /opt/clang+llvm-7.0.1/lib

# CMake
RUN mkdir /opt/cmake-3.14.5/ && \
    cd /opt/cmake-3.14.5/ && \
    wget --progress=dot:giga https://cmake.org/files/v3.14/cmake-3.14.5-Linux-x86_64.tar.gz -O - \
        | tar -xz --strip-components=1 && \
    for file in bin/*; \
    do \
        ln -s $PWD/$file /usr/bin/$(basename $file); \
    done

# Copy cppcheck over from builder
COPY --from=cppcheck-builder /opt/ /opt/

RUN for bin in /opt/cppcheck-1.*/bin/cppcheck-1.*; do \
        ln -s $bin /usr/bin/; \
    done

# Copy boost over from builder
COPY --from=boost-builder /opt/ /opt/

RUN for file in /opt/boost-1.70.0/include/*; do \
        ln -s $file /usr/include/; \
    done && \
    for file in /opt/boost-1.70.0/lib/*; do \
        ln -s $file /usr/lib/; \
    done

ENV CMAKE_PREFIX_PATH $CMAKE_PREFIX_PATH:/opt/boost-1.70.0

# Copy AWS SDK over from builder and install dependencies
COPY --from=aws-sdk-cpp-builder /opt/aws-sdk-cpp-1.7/ /opt/aws-sdk-cpp-1.7/

ENV CMAKE_PREFIX_PATH $CMAKE_PREFIX_PATH:/opt/aws-sdk-cpp-1.7

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libcurl4-openssl-dev \
        libpulse-dev \
        libssl-dev \
        uuid-dev \
        zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy arrow over from builder
COPY --from=arrow-builder /opt/arrow-0.14/ /opt/arrow-0.14/

ENV CMAKE_PREFIX_PATH $CMAKE_PREFIX_PATH:/opt/arrow-0.14

RUN pip3 install /opt/arrow-*/share/*.whl

# Other packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        libgraphviz-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Python packages
RUN pip3 install --upgrade \
        astroid==2.2.5 \
        attrs==19.1.0 \
        autopep8==1.4.3 \
        cffi==1.12.2 \
        cycler==0.10.0 \
        dask==1.1.5 \
        isort==4.3.16 \
        jsonmerge==1.6.0 \
        jsonschema==3.0.1 \
        kiwisolver==1.0.1 \
        lazy-object-proxy==1.3.1 \
        llvmlite==0.28.0 \
        matplotlib==3.0.3 \
        mccabe==0.6.1 \
        numba==0.42.0 \
        numpy==1.16.2 \
        pandas==0.24.2 \
        psutil==5.6.1 \
        py4j==0.10.7 \
        pycodestyle==2.5.0 \
        pycparser==2.19 \
        pylint==2.3.1 \
        pyparsing==2.3.1 \
        pyrsistent==0.14.11 \
        pyspark==2.4.0 \
        python-dateutil==2.8.0 \
        pytz==2018.9 \
        scikit-learn==0.20.3 \
        scipy==1.2.1 \
        six==1.12.0 \
        sklearn==0.0 \
        typed-ast==1.3.1 \
        wrapt==1.11.1 \
    && rm -r ~/.cache/pip
