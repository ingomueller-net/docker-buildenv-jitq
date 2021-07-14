FROM ingomuellernet/arrow:0.14-4 as arrow-builder
FROM ingomuellernet/aws-sdk-cpp:1.7.138-1 as aws-sdk-cpp-builder
FROM ingomuellernet/boost:1.76.0 as boost-builder
FROM ingomuellernet/cppcheck:1.80-1.90 as cppcheck-builder

FROM ubuntu:focal
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

# Basics
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        git \
        libstdc++-10-dev \
        libtinfo5 \
        libtinfo-dev \
        pkg-config \
        python3-pip \
        wget \
        xz-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clang+LLVM
RUN mkdir /opt/clang+llvm-11.1.0/ && \
    cd /opt/clang+llvm-11.1.0/ && \
    wget --progress=dot:giga https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/clang+llvm-11.1.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz -O - \
         | tar -x -I xz --strip-components=1 && \
    for file in bin/*; \
    do \
        ln -s $PWD/$file /usr/bin/$(basename $file)-11.1; \
    done && \
    ln -s libomp.so /opt/clang+llvm-11.1.0/lib/libomp.so.5 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-11.1 100 && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-11.1 100

ENV CMAKE_PREFIX_PATH $CMAKE_PREFIX_PATH:/opt/clang+llvm-11.1.0

# CMake
RUN mkdir /opt/cmake-3.21.0/ && \
    cd /opt/cmake-3.21.0/ && \
    wget --progress=dot:giga https://github.com/Kitware/CMake/releases/download/v3.21.0/cmake-3.21.0-linux-x86_64.tar.gz -O - \
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

RUN for file in /opt/boost-1.76.0/include/*; do \
        ln -s $file /usr/include/; \
    done && \
    for file in /opt/boost-1.76.0/lib/*; do \
        ln -s $file /usr/lib/; \
    done

ENV CMAKE_PREFIX_PATH $CMAKE_PREFIX_PATH:/opt/boost-1.76.0

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
        graphviz \
        time \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Python packages
# cython is required to build this version of scikit-learn
RUN pip3 install --upgrade cython && \
    pip3 install --upgrade \
        astroid==2.4.2 \
        attrs==20.3.0 \
        autopep8==1.5.4 \
        boto3==1.16.16 \
        botocore==1.19.16 \
        cffi==1.14.3 \
        cycler==0.10.0 \
        dask==1.2.2 \
        gcovr==4.2 \
        importlib-metadata==2.0.0 \
        iniconfig==1.1.1 \
        isort==5.6.4 \
        Jinja2==2.11.2 \
        jmespath==0.10.0 \
        joblib==0.17.0 \
        jsonmerge==1.7.0 \
        jsonschema==3.2.0 \
        kiwisolver==1.3.1 \
        lazy-object-proxy==1.4.3 \
        llvmlite==0.31.0 \
        lxml==4.6.1 \
        MarkupSafe==1.1.1 \
        matplotlib==3.3.3 \
        mccabe==0.6.1 \
        numba==0.48.0 \
        numpy==1.19.4 \
        packaging==20.4 \
        pandas==0.25.3 \
        Pillow==8.0.1 \
        pluggy==0.13.1 \
        psutil==5.7.3 \
        py==1.9.0 \
        py4j==0.10.9 \
        pycodestyle==2.6.0 \
        pycparser==2.20 \
        pylint==2.6.0 \
        pyparsing==2.4.7 \
        pyrsistent==0.17.3 \
        pyspark==3.0.1 \
        pytest==6.1.2 \
        python-dateutil==2.8.1 \
        pytz==2020.4 \
        s3transfer==0.3.3 \
        scikit-learn==0.21.3 \
        scipy==1.5.4 \
        six==1.15.0 \
        toml==0.10.2 \
        typed-ast==1.4.1 \
        urllib3==1.25.11 \
        wrapt==1.12.1 \
        zipp==3.4.0 \
    && rm -r ~/.cache/pip
