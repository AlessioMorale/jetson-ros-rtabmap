ARG sourceimage
FROM $sourceimage
COPY ./buildfiles/* /ros_rtabmap_ws/

# Install rtabmap & prerequisites https://github.com/introlab/rtabmap/blob/master/docker/bionic/Dockerfile
WORKDIR /root/

RUN git clone https://github.com/RainerKuemmerle/g2o.git && \ 
    cd g2o && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_WITH_MARCH_NATIVE=OFF -DG2O_BUILD_APPS=OFF -DG2O_BUILD_EXAMPLES=OFF -DG2O_USE_OPENGL=OFF .. && \
    make -j4 && \
    sudo make install && \
    cd && rm -rf g2o

# GTSAM
RUN git clone https://bitbucket.org/gtborg/gtsam.git && \
    cd gtsam && \
    git checkout 4.0.0-alpha2 && \
    mkdir build && \
    cd build && \
    cmake -DMETIS_SHARED=ON -DGTSAM_BUILD_STATIC_LIBRARY=OFF -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && \
    make install && \
    cd && \
    rm -r gtsam

# libpointmatcher 
RUN git clone https://github.com/ethz-asl/libnabo.git
#commit Apr 25 2018
RUN cd libnabo && \
    git checkout 7e378f6765393462357b8b74d8dc8c5554542ae6 && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && \
    make install && \
    cd && \
    rm -r libnabo
RUN git clone https://github.com/ethz-asl/libpointmatcher.git
#commit Jan 19 2018
RUN cd libpointmatcher && \
    git checkout 00004bd41e44a1cf8de24ad87e4914760717cbcc && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && \
    make install && \
    cd && \
    rm -r libpointmatcher

# Clone source code
ARG CACHE_DATE=2016-01-01
RUN git clone https://github.com/introlab/rtabmap.git

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Build RTAB-Map project
RUN source /docker-entrypoint.sh && \
    cd rtabmap/build && \
    cmake -DWITH_ALICE_VISION=ON .. && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf rtabmap && \
    ldconfig

# build RTABMap-ros within its workspace
RUN source /docker-entrypoint.sh && \
    mkdir -p /ros_rtabmap_ws/src && \
    cd /ros_rtabmap_ws/src && \

    git clone https://github.com/introlab/rtabmap_ros.git && \
    cd .. && \
    catkin init && \
    catkin config -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so -DCMAKE_INSTALL_PREFIX=/opt/ros/melodic && \
    catkin build install && \
    cd && \
    rm -rf catkin_ws

RUN /ros_rtabmap_ws/build_workspace


!todo:


octomap