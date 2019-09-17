FROM ubuntu:16.04

LABEL maintainer="HappyStraw <fangyutao1993@hotmail.com>"

# 切换国内源
RUN sed -i.bak 's/archive.ubuntu.com/mirrors.aliyun.com/' /etc/apt/sources.list

# 添加32位库支持, 安装依赖库
# 为什么一句话就能实现要拆成这么多句, 因为一个失败整条语句都要重新 Build /(ㄒoㄒ)/~~
RUN dpkg --add-architecture i386 && apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
        openjdk-8-jdk \
        git-core \
        gnupg \
        flex \
        bison \
        gperf \
        build-essential \
        zip \
        curl \
        zlib1g-dev \
        libc6-dev-i386 \
        lib32ncurses5-dev \
        x11proto-core-dev \
        libx11-dev \
        lib32z-dev \
        ccache \
        libgl1-mesa-dev \
        libxml2-utils \
        xsltproc \
        unzip \
        lib32z1-dev \
        qemu \
        g++-multilib \
        gcc-multilib \
        libglib2.0-dev \
        libpixman-1-dev \
        linux-libc-dev:i386
RUN apt-get install -y gcc-5-aarch64-linux-gnu g++-5-aarch64-linux-gnu
RUN apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /data

# 下载源码
RUN git clone https://gitee.com/harmonyos/OpenArkCompiler.git openarkcompiler

# 下载 gn
RUN curl -L -o gn https://archive.softwareheritage.org/browse/content/sha1_git:2dc0d5b26caef44f467de8120b26f8aad8b878be/raw/?filename=gn

# 下载 nijia
RUN curl -L -o ninja-linux.zip https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-linux.zip

# 下载 LVVM 文件
RUN curl -L -o clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz http://releases.llvm.org/8.0.0/clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz
# 替代方案 -- 如果总是下载失败
## 1. 映射到本机IP, 本地的搭建文件服务
##    docker build --add-host releases.llvm.org:192.168.97.71 -t openarkcompiler .
## 2. 使用 COPY 指令 复制本地已经下载完的 LVVM 文件
##    COPY ./clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz .

# 解压 nijia
RUN unzip ninja-linux.zip

# 解压 lvvm
RUN tar -xvf clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz

# 移动文件
RUN chmod 755 gn ninja \
    && mkdir -p ./openarkcompiler/tools/gn \
    && mv ./gn ./openarkcompiler/tools/gn \
    && mkdir -p ./openarkcompiler/tools/ninja_1.9.0 \
    && mv ./ninja ./openarkcompiler/tools/ninja_1.9.0 \
    && mv ./clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04 ./openarkcompiler/tools/clang_llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04

# 清理文件
RUN rm ./ninja-linux.zip ./clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz

# 编译方舟
RUN /bin/bash -c 'cd ./openarkcompiler && source build/envsetup.sh && make'

# 将环境初始化写入 bash 启动初始化脚本
RUN echo 'cd /data/openarkcompiler && source build/envsetup.sh && unset curdir && cd - >> /dev/null' >> /root/.bashrc

# 设置全局变量, 允许直接 maple 调用
# 如: docker run -it --rm openarkcompiler maple
ENV PATH /data/openarkcompiler/out/bin:$PATH


# +---------------------------------------------------------
# + 以下为修改支持编译 helloworld
# +---------------------------------------------------------

# 切换到方舟源码目录
WORKDIR /data/openarkcompiler

# 下载 java-core
RUN git clone https://gitee.com/mirrors/java-core.git libjava-core

# 生成编译需要的 libjava-core.mplt , 这个步骤会比较久
RUN cd libjava-core && jbc2mpl -injar java-core.jar -out libjava-core

# 可以测试编译示例代码
# cd sample/helloword && make