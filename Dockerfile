# https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cuda/tags
FROM nvcr.io/nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

# Let us install tzdata painlessly
ENV DEBIAN_FRONTEND=noninteractive

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
# Pick up some TF dependencies


###################################################################################################
# Install some libraries
###################################################################################################

RUN apt update && apt install -y --no-install-recommends \
        curl \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip \
        git \
        vim \
        eog \
        libgl1-mesa-dev

RUN apt update && apt install -y --no-install-recommends wget git cmake gedit



###################################################################################################
# Install CUDA10.2
# https://developer.nvidia.com/cuda-10.0-download-archive?target_os=Linux&target_arch=x86_64&
# target_distro=Ubuntu&target_version=1804&target_type=deblocal
###################################################################################################
#COPY ./cuda_file/cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64.deb ./
#RUN dpkg -i cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64.deb
#RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
#RUN apt update
#RUN apt -y install --no-install-recommends cuda-toolkit-10-0



###################################################################################################
# Install cudnn7.4.2.24
# https://qiita.com/TsuchiyaYutaro/items/10d399686ce778cb9ffa
# https://developer.nvidia.com/rdp/cudnn-archive
###################################################################################################
COPY ./cuda_file/libcudnn7-dev_7.4.2.24-1+cuda10.0_amd64.deb ./
COPY ./cuda_file/libcudnn7_7.4.2.24-1+cuda10.0_amd64.deb ./
COPY ./cuda_file/cudnn-10.0-linux-x64-v7.4.2.24.tgz ./

RUN dpkg -i libcudnn7_7.4.2.24-1+cuda10.0_amd64.deb
RUN dpkg -i libcudnn7-dev_7.4.2.24-1+cuda10.0_amd64.deb
RUN tar -zxf cudnn-10.0-linux-x64-v7.4.2.24.tgz

RUN cp cuda/include/cudnn.h /usr/local/cuda/include/
RUN cp -R cuda/lib64/* /usr/local/cuda/lib64/


RUN echo -e "\n## CUDA and cuDNN paths"  >> ~/.bashrc
RUN echo 'export PATH=/usr/local/cuda-10.0/bin:${PATH}' >> ~/.bashrc
RUN echo 'export LD_LIBRARY_PATH=/usr/local/cuda-10.0/lib64:${LD_LIBRARY_PATH}' >> ~/.bashrc


# ARCH and CUDA are specified again because the FROM directive resets ARGs
# (but their default value is retained if set previously)
ARG ARCH
ARG CUDA=10.0
ARG CUDNN=7.4.2.24-1
ARG CUDNN_MAJOR_VERSION=7
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=7.4.2-1
ARG LIBNVINFER_MAJOR_VERSION=7

# Let us install tzdata painlessly
ENV DEBIAN_FRONTEND=noninteractive

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
# Pick up some TF dependencies

# libgl1-mesa-dev is need for use OpenCV
# https://cocoinit23.com/docker-opencv-importerror-libgl-so-1-cannot-open-shared-object-file/

RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub && \
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-${CUDA/./-} \
        cuda-nvrtc-${CUDA/./-} \
        curl \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip \
        git \
        vim \
        eog \
        wget \
        libgl1-mesa-dev



# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda-10.0/targets/x86_64-linux/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig


# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

###################################################################################################
# start install python3.7
# https://www.linuxcapable.com/install-python-3-8-on-ubuntu-linux/
###################################################################################################

RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt update
RUN apt install -y python3.7
RUN apt install -y python3.7-dbg python3.7-dev python3.7-distutils \
                   python3.7-lib2to3 python3.7-tk

# Set alias
RUN echo 'alias python=python3.7' >> ~/.bashrc
RUN echo 'alias pip=pip3' >> ~/.bashrc
RUN . ~/.bashrc

RUN apt autoremove -y


###################################################################################################
# setup pip
# https://www.linuxcapable.com/install-python-3-8-on-ubuntu-linux/
###################################################################################################

#RUN wget https://bootstrap.pypa.io/get-pip.py
RUN curl https://bootstrap.pypa.io/pip/3.7/get-pip.py -o get-pip.py
RUN python3.7 get-pip.py
RUN python3.7 -m pip install --upgrade pip

#COPY bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc

RUN apt autoremove -y 
#EXPOSE 8888

###################################################################################################
# Install Tensorflow-gpu 1.15 using pip
# 
###################################################################################################

COPY ./requirements.txt ./
RUN pip install --no-cache-dir Cython
RUN pip install --no-cache-dir -r requirements.txt

###################################################################################################
# set X windows and GL to bashrc
# https://stackoverflow.com/questions/66497147/cant-run-opengl-on-wsl2#:~ \ 
# :text=To%20solve%20this%2C%20do%20the%20following%3A%20In%20the, \ 
# your%20bashrc%2Fzshrc%20file%20if%20you%20have%20added%20it.
###################################################################################################

RUN echo 'export DISPLAY=:0.0' >> ~/.bashrc 
RUN echo 'export LIBGL_ALWAYS_INDIRECT=0' >> ~/.bashrc
RUN echo 'export PATH="/usr/local/cuda/bin:$PATH"' >> ~/.bashrc
RUN echo 'export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"' >> ~/.bashrc
RUN source ~/.bashrc

