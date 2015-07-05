# Install boot2docker (Tiny Core Linux) to the hard disk
# See: http://distro.ibiblio.org/tinycorelinux/install_manual.html

# partition drive
echo -e "o\nn\np\n1\n\n\na\n1\nw" | sudo fdisk /dev/sda

# format partition and mount
mkfs.ext4 -I 256 /dev/sda1
sudo rebuildfstab
sudo mount /mnt/sda1

# add boot2docker system files from the boot ISO
sudo mkdir -p /mnt/sda1/boot
sudo mount /mnt/sr0
sudo cp -p /mnt/sr0/boot/vmlinuz64 /mnt/sr0/boot/initrd.img /mnt/sda1/boot

# install boot loader
sudo mkdir -p /mnt/sda1/boot/extlinux
sudo /usr/local/sbin/extlinux --install /mnt/sda1/boot/extlinux
sudo dd bs=440 count=1 conv=notrunc if=/usr/local/share/syslinux/mbr.bin of=/dev/sda
sudo cp /usr/local/share/syslinux/*menu* /mnt/sda1/boot/extlinux
cd /mnt/sda1/boot/extlinux
sudo sh -c "cat > syslinux.cfg" << EOF
DEFAULT boot2docker
LABEL boot2docker
  KERNEL /boot/vmlinuz64
  APPEND root=/dev/sda1 home=sda1 opt=sda1 tce=sda1 loglevel=3 console=ttyS0 console=tty0 nomodeset noembed noautologin
  INITRD /boot/initrd.img
  
  # boot2docker ISO default flags:
  # loglevel=3 user=docker console=ttyS0 console=tty0 noembed nomodeset norestore waitusb=10:LABEL=boot2docker-data base
EOF

# create script to be run at startup
sudo mkdir -p /mnt/sda1/var/lib/boot2docker
cd /mnt/sda1/var/lib/boot2docker
sudo sh -c "cat > bootlocal.sh" << EOF
#!/bin/sh

if [ -e /opt/passwd ]; then
    # If user settings exist, copy them to system folder...
    cd /opt; cp passwd shadow group sudoers /etc
else
    # ...otherwise create the vagrant user
    adduser -D -G staff -s /bin/sh vagrant
    echo 'vagrant:vagrant' | chpasswd
    cd /home/vagrant
    mkdir -m 700 .ssh
    # from https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key' \
            > .ssh/authorized_keys
    chmod 600 .ssh/authorized_keys
    chown -R vagrant:staff .ssh
    echo 'vagrant ALL=NOPASSWD: ALL' >> /etc/sudoers
    
    # disable other users
    passwd -d root
    passwd -d tc
    passwd -d docker
    
    # Copy user settings to persistent folder
    cd /etc; cp passwd shadow group sudoers /opt
fi
EOF
sudo chmod +x bootlocal.sh
