```docker
docker run -i -t ubuntu:20.04 /bin/bash
```
- -i  => keeps your terminal *interactive* (STDIN open).
	- Allows you to "type commands" into the container. Without -i the container won't accept your keyboard input.
- -t => Allocates a *Pseudo-terminal*
- /bin/ -> tells docker **what process to run inside the container**
	- A standard `Linux directory`
	- Contains essencial **system programs** (ls, cp, sh, bash, etc)


# docker images / commands

* Docker diff <container_id> - shows filesystem made inside a running or stopped container compared to its original image.
* Docker commit <image_name> - creates the docker image

# Creating the image with YML

* The most common Docker YAML file, used to define and run multi-container - * Docker applications. It allows you to configure:
  Services: Multiple containers that make up your application
* Networks: How containers communicate with each other
* Volumes: Persistent data storage
* Environment variables: Configuration settings
* Port mappings: Exposing container ports to the host
* Dependencies: Which services depend on others

# Build image command
* docker build -t <container_name> path
**ATTENTION**: *Docker images are **read-only**. Containers add a **writable layer** on top. * 