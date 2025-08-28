#|=-----------------------------------------------------------------------=|
#|=-----------------------=[    afl-build    ]=---------------------------=|
#|=-----------------------------------------------------------------------=|
ARG OS_VER=latest
ARG LLVM_VER=18
FROM docker.io/ubuntu:${OS_VER} AS afl-build
ARG LLVM_VER=18
# Required when behind a proxy due to caching issues
#   https://askubuntu.com/a/160179
RUN apt-get clean
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential \
    python3-dev \
    automake \
    cmake \
    git \
    flex \
    bison \
    libglib2.0-dev \
    libpixman-1-dev \
    python3-setuptools \
    cargo \
    libgtk-3-dev \
    lld-${LLVM_VER} \
    llvm-${LLVM_VER} \
    llvm-${LLVM_VER}-dev \
    clang-${LLVM_VER} \
    ninja-build \
    cpio \
    libcapstone-dev \
    wget \
    curl \
    python3-pip
RUN bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y gcc-$(gcc --version|head -n1|sed 's/\..*//'|sed 's/.* //')-plugin-dev libstdc++-$(gcc --version|head -n1|sed 's/\..*//'|sed 's/.* //')-dev"

RUN git clone https://github.com/AFLplusplus/AFLplusplus
RUN cd /AFLplusplus && make PERFORMANCE=1 distrib
RUN cd /AFLplusplus && make install PREFIX=/opt/AFLplusplus
RUN cd / && rm -r /AFLplusplus

#|=-----------------------------------------------------------------------=|
#|=-----------------------=[    app-build    ]=---------------------------=|
#|=-----------------------------------------------------------------------=|
FROM docker.io/ubuntu:${OS_VER} AS app-build
ARG LLVM_VER=18
COPY --from=afl-build /opt/AFLplusplus /opt/AFLplusplus

# install AFL++
RUN cp -r /opt/AFLplusplus/* /usr/local/

# Required when behind a proxy due to caching issues
#   https://askubuntu.com/a/160179
RUN apt-get clean
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential \
    curl \
    gcc \
    cmake \
    llvm-${LLVM_VER} \
    llvm-${LLVM_VER}-dev \
    clang-${LLVM_VER} \
    git
