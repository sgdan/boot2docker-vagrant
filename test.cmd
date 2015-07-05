vagrant destroy -f
vagrant box add --force boot2docker boot2docker.box
vagrant up
vagrant ssh -c "sudo docker run -it --rm hello-world"