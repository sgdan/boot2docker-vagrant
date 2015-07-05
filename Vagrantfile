# -*- mode: ruby -*-
# vi: set ft=ruby :

# Host VM for docker containers
Vagrant.configure(2) do |config|
  config.vm.box = "boot2docker"
  config.ssh.shell = "/bin/sh"
  
  # Assign a private IP address
  config.vm.network "private_network", ip: "10.1.2.3"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "512"
  end
end
