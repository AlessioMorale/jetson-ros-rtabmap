FROM alessiomorale/jetson-ros-perception:melodic_r32.4.4_cv4.4.0_2

# Install rtabmap & prerequisites https://github.com/introlab/rtabmap/blob/master/docker/bionic/Dockerfile
WORKDIR /root/
SHELL ["/bin/bash", "-c"]

ENV CCACHE_ROOT_FOLDER=/ccache
RUN mkdir -p ${CCACHE_ROOT_FOLDER}

RUN sudo apt-get update && \
    sudo apt-get install \
    ros-melodic-libg2o \
    ros-melodic-octomap \
    ros-melodic-octomap-ros \
    ros-melodic-octomap-server \
    liblapack-dev \
    libf2c2-dev \
    libsuitesparse-dev \
    libceres-dev xorg-dev \
    libglu1-mesa-dev \
    wget \
    libopenexr22 \
    libopenexr-dev \
    -y --no-install-recommends && \
    apt-get clean autoclean -y

ARG BUILD_JOBS="6"

# GTSAM
RUN --mount=type=secret,id=secrets,dst=/secrets \
    --mount=type=cache,id=rtabmap,target=/ccache \
    source /secrets && \
    source /root/setup_ccache && \
    download_cache && \
    git clone https://bitbucket.org/gtborg/gtsam.git && \
    cd gtsam && \
    git checkout 4.0.0-alpha2 && \
    mkdir build && \
    cd build && \
    cmake -DMETIS_SHARED=ON -DGTSAM_BUILD_STATIC_LIBRARY=OFF -DGTSAM_WITH_EIGEN_MKL=OFF -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF -DCMAKE_BUILD_TYPE=Release .. && \
    make -j${BUILD_JOBS} && \
    upload_cache && \
    make install && \
    cd && \
    rm -r gtsam

# libpointmatcher
RUN --mount=type=secret,id=secrets,dst=/secrets \
    --mount=type=cache,id=rtabmap,target=/ccache \
    source /secrets && \
    source /root/setup_ccache && \
    git clone https://github.com/ethz-asl/libnabo.git && \
    cd libnabo && \
    git checkout 7e378f6765393462357b8b74d8dc8c5554542ae6 && \
    mkdir build && \
    cd build && \
    cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m \
    -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so \
    .. && \
    make -j${BUILD_JOBS} && \
    upload_cache && \
    make install && \
    cd && \
    rm -r libnabo

RUN --mount=type=secret,id=secrets,dst=/secrets \
    --mount=type=cache,id=rtabmap,target=/ccache \
    source /secrets && \
    source /root/setup_ccache && \
    git clone https://github.com/ethz-asl/libpointmatcher.git && \
    cd libpointmatcher && \
    git checkout 00004bd41e44a1cf8de24ad87e4914760717cbcc && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j${BUILD_JOBS} && \
    upload_cache && \
    make install && \
    cd && \
    rm -r libpointmatcher

RUN mkdir -p /ros_rtabmap_ws/src
COPY ./resources/* /ros_rtabmap_ws/

# build the workspace
WORKDIR /ros_rtabmap_ws
RUN for i in *.rosinstall; do echo - $i && vcs import src < `echo $i`; done

RUN source /docker-entrypoint.sh && \
    rosdep install --from-paths src --ignore-src --rosdistro melodic -y --skip-keys='rviz rtabmap' && \
    apt-get clean autoclean -y

RUN --mount=type=secret,id=secrets,dst=/secrets \
    --mount=type=cache,id=rtabmap,target=/ccache \
    source /secrets && \
    source /root/setup_ccache && \
    source /docker-entrypoint.sh && \
    catkin config -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m \
    -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so \
    -DRTABMAP_GUI=OFF \
    -DWITH_OPENNI2=OFF \
    -DWITH_FREENECT=OFF \
    -DWITH_FREENECT2=OFF \
    -DWITH_G2O=ON \
    -DWITH_QT=OFF \
    -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda/ && \
    time catkin build --no-status --interleave -j${BUILD_JOBS} && \
    upload_cache

# Set up entrypoint
RUN echo "source /ros_rtabmap_ws/devel/setup.bash" >> /init_workspaces

#octomap
