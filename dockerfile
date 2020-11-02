FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

ENV STAGE_DIR=/root/drivers \
    PYTHONPATH=/modules

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y install \
        build-essential \
        gcc \
        g++ \
        binutils \
        pciutils \
        bind9-host \
        bc \
        libssl-dev \
        sudo \
        dkms \
        net-tools \
        iproute2 \
        software-properties-common \
        git \
        vim \
        wget \
        curl \
        make \
        jq \
        psmisc \
        python \
        python-dev \
        python-yaml \
        python-jinja2 \
        python-urllib3 \
        python-tz \
        python-nose \
        python-prettytable \
        python-netifaces \
        python-pip \
        coreutils \
        gawk \
        module-init-tools \
        # For MLNX OFED
        ethtool \
        lsof \
        python-libxml2 \
        quilt \
        libltdl-dev \
        dpatch \
        autotools-dev \
        graphviz \
        autoconf \
        chrpath \
        swig \
        automake \
        # tk8.4 \
        # tcl8.4 \
        libgfortran3 \
        tcl \
        gfortran \
        libnl-3-200 \
        libnl-3-dev \
        libnl-route-3-200 \
        libnl-route-3-dev \
        libcr-dev \
        libcr0 \
        pkg-config \
        flex \
        debhelper \
        bison \
        tk \
        libelf-dev \
        libaudit-dev \
        libslang2-dev \
        libgtk2.0-dev \
        libperl-dev \
        liblzma-dev \
        libnuma-dev \
        libglib2.0-dev \
        libegl1 \
        libopengl0 \
        libnuma1 \
        libtool \
        libdw-dev \
        libiberty-dev \
        libunwind8-dev \
        binutils-dev && \
    pip install subprocess32 && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    mkdir -p $STAGE_DIR

WORKDIR $STAGE_DIR

ENV NVIDIA_VERSION=430.40 \
    OFED_VERSION=4.3-3.0.2.1 \
    OS_VERSION=ubuntu18.04 \
    ARCHITECTURE=x86_64

ENV MLNX_OFED_STRING=MLNX_OFED_LINUX-${OFED_VERSION}-${OS_VERSION}-${ARCHITECTURE}

RUN wget --no-verbose http://us.download.nvidia.com/XFree86/Linux-x86_64/$NVIDIA_VERSION/NVIDIA-Linux-x86_64-$NVIDIA_VERSION.run && \
    chmod 750 ./NVIDIA-Linux-x86_64-$NVIDIA_VERSION.run && \
    ./NVIDIA-Linux-x86_64-$NVIDIA_VERSION.run --extract-only && \
    rm ./NVIDIA-Linux-x86_64-$NVIDIA_VERSION.run

RUN echo "wget -q -O - http://www.mellanox.com/downloads/ofed/MLNX_OFED-$OFED_VERSION/$MLNX_OFED_STRING.tgz | tar xzf -" && \
    wget -q -O - http://www.mellanox.com/downloads/ofed/MLNX_OFED-$OFED_VERSION/$MLNX_OFED_STRING.tgz | tar xzf - && \
    echo "wget -q -O - http://www.mellanox.com/downloads/ofed/nvidia-peer-memory_1.0.5.tar.gz | tar xzf -" && \
    wget -q -O - http://www.mellanox.com/downloads/ofed/nvidia-peer-memory_1.0.5.tar.gz | tar xzf - && \
    git clone https://github.com/NVIDIA/gdrcopy.git

RUN cd $MLNX_OFED_STRING/DEBS && \
    for dep in libibverbs1 libibverbs-dev ibverbs-utils libmlx4-1 libmlx5-1 librdmacm1 librdmacm-dev libibumad libibumad-devel libibmad libibmad-devel libopensm infiniband-diags mlnx-ofed-kernel-utils; do \
        dpkg -i $dep\_*_amd64.deb && \
    dpkg --contents $dep\_*_amd64.deb | while read i; do \
        src="/$(echo $i | cut -f6 -d' ')" && \
        dst="$STAGE_DIR/$MLNX_OFED_STRING/usermode$(echo $src | sed -e 's/\.\/usr//' | sed -e 's/\.\//\//')" && \
        (([ -d $src ] && mkdir -p $dst) || \
         ([ -h $src ] && cd $(dirname $dst) && ln -s -f $(echo $i | cut -f8 -d' ') $(basename $dst) && cd $STAGE_DIR/$MLNX_OFED_STRING/DEBS) || \
         ([ -f $src ] && cp $src $dst) \
        ); \
    done; \
    done

COPY ./* $STAGE_DIR/
RUN chmod a+x enable-nvidia-persistenced-mode.sh install-all-drivers install-gdr-drivers install-ib-drivers install-nvidia-drivers config-docker-runtime.sh clean.sh

RUN ln -s /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/ && ldconfig

CMD /bin/bash install-all-drivers