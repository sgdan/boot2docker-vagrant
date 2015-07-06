vagrant destroy -f
vagrant box add --force boot2docker boot2docker.box
vagrant up
vagrant ssh -c "docker run -it hello-world"
vagrant ssh -c "docker images"
vagrant ssh -c "docker ps -a"
