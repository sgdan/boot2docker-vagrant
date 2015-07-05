# Scripts to create vagrant box based on boot2docker

- [Dockerfile](dockerfile) to create a Tiny Core ISO install image. Create boot2docker-install.iso
in the output directory:

	`docker build -t boot2docker .`

	`docker run -it --rm -v /output:/output boot2docker`


- Packer script [build.json](build.json) to install boot2docker to a VirtualBox 
hard drive, and create vagrant box.

    `packer build build.json`