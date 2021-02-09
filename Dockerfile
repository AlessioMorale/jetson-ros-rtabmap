ARG sourceimage
FROM $sourceimage

# Install rtabmap & prerequisites https://github.com/introlab/rtabmap/blob/master/docker/bionic/Dockerfile
WORKDIR /root/
ARG BUILD_JOBS="6"

RUN sudo apt-get update && sudo apt-get install ros-melodic-libg2o ros-melodic-octomap ros-melodic-octomap-ros ros-melodic-octomap-server liblapack-dev libf2c2-dev -y --no-install-recommends &&  apt-get clean autoclean -y
SHELL ["/bin/bash", "-c"]

# GTSAM
RUN git clone https://bitbucket.org/gtborg/gtsam.git && \
    cd gtsam && \
    git checkout 4.0.0-alpha2 && \
    mkdir build && \
    cd build && \
    cmake -DMETIS_SHARED=ON -DGTSAM_BUILD_STATIC_LIBRARY=OFF -DGTSAM_WITH_EIGEN_MKL=OFF -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF -DCMAKE_BUILD_TYPE=Release .. && \
    make -j${BUILD_JOBS} && \
    make install && \
    cd && \
    rm -r gtsam

# libpointmatcher
RUN git clone https://github.com/ethz-asl/libnabo.git && \
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
    make install && \
    cd && \
    rm -r libnabo

RUN git clone https://github.com/ethz-asl/libpointmatcher.git && \
    cd libpointmatcher && \
    git checkout 00004bd41e44a1cf8de24ad87e4914760717cbcc && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j${BUILD_JOBS} && \
    make install && \
    cd && \
    rm -r libpointmatcher

RUN apt-get update && \
    apt-get install libsuitesparse-dev libceres-dev xorg-dev libglu1-mesa-dev wget libopenexr22 libopenexr-dev -y --no-install-recommends && \
    apt-get clean autoclean -y

RUN git clone https://github.com/AlessioMorale/g2o.git && \
    cd g2o && \
    git checkout fix_arm_targets && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_WITH_MARCH_NATIVE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DG2O_BUILD_APPS=OFF \
    -DG2O_BUILD_EXAMPLES=OFF \
    -DG2O_USE_OPENGL=OFF \
    .. && \
    make -j${BUILD_JOBS} && \
    make install && \
    cd && \
    rm -r g2o

RUN mkdir -p /ros_rtabmap_ws/src
COPY ./buildfiles/* /ros_rtabmap_ws/

# build the workspace
WORKDIR /ros_rtabmap_ws
RUN for i in *.rosinstall; do echo - $i && vcs import src < `echo $i`; done

RUN source /docker-entrypoint.sh && \
    rosdep install --from-paths src --ignore-src --rosdistro melodic -y --skip-keys='python3-opencv opencv libopencv-dev libopencv rviz rtabmap' && \
    apt-get clean autoclean -y

RUN source /docker-entrypoint.sh && \
    catkin config -DCMAKE_BUILD_TYPE=Release \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m \
    -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so \
    -DRTABMAP_GUI=OFF \
    -DWITH_G2O=ON \
    -DWITH_QT=OFF && \
    catkin build --no-status --interleave -j${BUILD_JOBS}

# Set up entrypoint
RUN echo "source /ros_rtabmap_ws/devel/setup.bash" >> /init_workspaces

#octomap
