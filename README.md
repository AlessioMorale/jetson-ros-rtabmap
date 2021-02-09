# jetson-ros-dockers: jetson-ros-perception
A docker container to be used to build and execute ros workspaces based on ros-perception for L4T/arm64

To build the repository on an amd64 workstation you can use the following script.
Check the blog post [Running Docker Containers for the NVIDIA Jetson Nano](https://dev.to/caelinsutch/running-docker-containers-for-the-nvidia-jetson-nano-5a06) for more info.

```bash
#Configure docker for Nvidia
# Add the package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Configure aarch64 emulation
sudo apt-get install qemu binfmt-support qemu-user-static # Install the qemu packages  

docker run --rm --privileged multiarch/qemu-user-static --reset -p yes # This step will execute the registering scripts  

```

To run interactively the builder image you can use the following sintax:

```bash
docker run -it --rm --net=host --runtime nvidia -v -v <your_workspace_path>:/ros_catkin_ws -e DISPLAY=$DISPLAY alessiomorale/ros-builder-melodic-jp-r32.4.2-cv-4.3.0-0:0.2.0
```

Images are based on [alessiomorale/ros-builder-melodic-jp-r32.4.2-cv-4.3.0-0](https://github.com/AlessioMorale/jetson-ros-builder) based on [mdegans/tegra-opencv](https://github.com/mdegans/nano_build_opencv/tree/docker)