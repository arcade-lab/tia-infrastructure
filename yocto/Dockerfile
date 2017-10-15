FROM centos:7

# Prerequisite packages for Yocto.
RUN yum install gawk make wget tar bzip2 gzip python unzip perl patch \
    diffutils diffstat git cpp gcc gcc-c++ glibc-devel texinfo chrpath socat \
    perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue SDL-devel xterm -y
RUN yum install file which iproute -y
RUN yum install epel-release -y
RUN yum install python34 -y

# Add a build user and switch to it.
RUN useradd -ms /bin/bash build
USER build
WORKDIR /home/build

# Set locale.
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
