ARG sourceimage
FROM $sourceimage

# Install rtabmap & prerequisites https://github.com/introlab/rtabmap/blob/master/docker/bionic/Dockerfile
WORKDIR /root/

RUN sudo apt-get update && sudo apt-get install ros-melodic-libg2o ros-melodic-octomap ros-melodic-octomap-ros ros-melodic-octomap-server -y --no-install-recommends &&  apt-get clean autoclean -y
SHELL ["/bin/bash", "-c"]

# GTSAM
RUN git clone https://bitbucket.org/gtborg/gtsam.git && \
    cd gtsam && \
    git checkout 4.0.0-alpha2 && \
    mkdir build && \
    cd build && \
    cmake -DMETIS_SHARED=ON -DGTSAM_BUILD_STATIC_LIBRARY=OFF -DGTSAM_WITH_EIGEN_MKL=OFF -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && \
    make install && \
    cd && \
    rm -r gtsam

# libpointmatcher 
RUN git clone https://github.com/ethz-asl/libnabo.git && \
    cd libnabo && \
    git checkout 7e378f6765393462357b8b74d8dc8c5554542ae6 && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so .. && \
    make -j$(nproc) && \
    make install && \
    cd && \
    rm -r libnabo

RUN git clone https://github.com/ethz-asl/libpointmatcher.git && \
    cd libpointmatcher && \
    git checkout 00004bd41e44a1cf8de24ad87e4914760717cbcc && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && \
    make install && \
    cd && \
    rm -r libpointmatcher

# Build RTAB-Map project
RUN source /docker-entrypoint.sh && \
    git clone https://github.com/introlab/rtabmap.git && \
    cd rtabmap/build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && \
    rm -r rtabmap && \
    ldconfig

RUN mkdir -p /ros_rtabmap_ws/src
COPY ./buildfiles/* /ros_rtabmap_ws/

# build the workspace
WORKDIR /ros_rtabmap_ws
RUN for i in *.rosinstall; do echo - $i && vcs import src < `echo $i`; done

RUN source /docker-entrypoint.sh && rosdep install --from-paths src --ignore-src --rosdistro melodic -y --skip-keys='python3-opencv opencv libopencv-dev libopencv rviz rtabmap' --simulate && apt-get clean autoclean -y

RUN source /docker-entrypoint.sh && catkin config -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m -DPYTHON_LIBRARY=/usr/lib/aarch64-linux-gnu/libpython3.6m.so  -DRTABMAP_GUI=OFF && catkin build --no-status --interleave -v

# Set up entrypoint
RUN echo "source /ros_rtabmap_ws/devel/setup.bash" >> /init_workspaces

#octomap