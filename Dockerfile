#|=-----------------------------------------------------------------------=|
#|=-----------------------=[    app-build    ]=---------------------------=|
#|=-----------------------------------------------------------------------=|
ARG OS_VER=latest
ARG LLVM_VER=18
FROM docker.io/ubuntu:${OS_VER} AS app-build
ARG OS_VER=latest
ARG LLVM_VER=18
COPY --from=docker.io/tylerwarre/fuzz-base:${OS_VER} /opt/AFLplusplus /opt/AFLplusplus

# install AFL++
RUN cp -r /opt/AFLplusplus/* /usr/local/

# Required when behind a proxy due to caching issues
#   https://askubuntu.com/a/160179
RUN apt-get clean
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential \
    curl \
    gcc \
    llvm-${LLVM_VER} \
    llvm-${LLVM_VER}-dev \
    clang-${LLVM_VER} \
    libxt-dev \
    libmotif-dev
RUN mkdir /opt/xpdf-3.02/
# Uncomment if internet is available
#RUN cd /opt/xpdf-3.02 && curl -L -O https://dl.xpdfreader.com/old/xpdf-3.02.tar.gz
COPY ./xpdf-3.02.tar.gz /opt/xpdf-3.02
RUN cd /opt/xpdf-3.02 && tar xf xpdf-3.02.tar.gz && mv xpdf-3.02 ./src && mv xpdf-3.02.tar.gz ./src/
RUN chown -R 2000:2000 /opt/xpdf-3.02

USER 2000:2000

RUN cd /opt/xpdf-3.02/src && CC=afl-clang-fast CXX=afl-clang-fast++ ./configure --prefix=/opt/xpdf-3.02/fuzz --with-freetype2-library=/usr/lib/x86_64-linux-gnu --with-freetype2-includes=/usr/include/freetype2 && make
RUN cd /opt/xpdf-3.02/src && make install

#|=-----------------------------------------------------------------------=|
#|=--------------------------=[    run    ]=------------------------------=|
#|=-----------------------------------------------------------------------=|
ARG OS_VER=latest
ARG LLVM_VER=18
FROM docker.io/ubuntu:${OS_VER} AS run

ARG OS_VER=latest
ARG LLVM_VER=18

COPY --from=docker.io/tylerwarre/fuzz-base:${OS_VER} /opt/AFLplusplus /opt/AFLplusplus
COPY --from=app-build /opt/xpdf-3.02/ /opt/xpdf-3.02/

ENV FUZZ_SEED="tyler"
ENV FUZZ_RESUME=0

# re-enable man pages from minimized image
RUN sed -i 's:^path-exclude=/usr/share/man:#path-exclude=/usr/share/man:' /etc/dpkg/dpkg.cfg.d/excludes

# install AFL++
RUN cp -r /opt/AFLplusplus/* /usr/local/
RUN rm -r /opt/AFLplusplus/

# Required when behind a proxy due to caching issues
#   https://askubuntu.com/a/160179
RUN apt-get clean
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y man \
    manpages \
    man-db \
    manpages-posix \
    vim \
    tmux \
    git \
    gdb

# remove apt cache
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Restore minimized man pages
RUN mv /usr/bin/man.REAL /usr/bin/man
# Update man database
RUN mandb -c

RUN addgroup --gid 2000 fuzz && useradd -m -g 2000 -u 2000 fuzz
COPY ./samples /home/fuzz/samples
COPY ./tmux.conf /home/fuzz/.tmux.conf
RUN chown -R 2000:2000 /home/fuzz/*
COPY ./entry.sh /entry.sh
COPY ./stop-fuzz.sh /usr/local/bin/stop-fuzz
RUN chmod 755 /entry.sh
RUN chmod 755 /usr/local/bin/stop-fuzz

USER 2000:2000
RUN mkdir /home/fuzz/output
VOLUME /home/fuzz/output

WORKDIR /home/fuzz
ENTRYPOINT ["/entry.sh"]
