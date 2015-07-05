# Create an ISO image that can be used for hard-drive install of boot2docker.
#
# Intended to be used with packer to create a vagrant box for boot2docker.
#
# This is a remastered version of 32-bit Tiny Core Linux using syslinux as
# bootloader (since I couldn't get grub2 in the 64-bit version to work with
# VirtualBox).

# Install tools required to extract and build image
FROM debian:jessie
RUN apt-get update && apt-get install -y \
    wget \
    genisoimage \
    p7zip-full \
    squashfs-tools \
    cpio \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV BUILD /opt/build
ENV DIST /opt/dist
ENV BASE http://distro.ibiblio.org/tinycorelinux/6.x/x86

# download boot2docker ISO
RUN wget --quiet -O /opt/boot2docker.iso https://github.com/boot2docker/boot2docker/releases/download/v1.7.0/boot2docker.iso

# download Tiny Core Linux ISO (32-bit version)
RUN wget --quiet -O /opt/tinycore.iso $BASE/release/Core-6.3.iso

# download and unpack 32-bit extensions (bootloader and ssh client/server)
ENV EXTENSIONS syslinux openssh openssl-1.0.1
RUN mkdir tcz
RUN for extension in $EXTENSIONS; do \
        wget --quiet $BASE/tcz/$extension.tcz -P tcz; done
RUN for extension in $EXTENSIONS; do \
        unsquashfs -f -d $BUILD tcz/$extension.tcz; done
        
# extract Tiny Core boot files
WORKDIR $DIST
RUN 7z x /opt/tinycore.iso boot/*

# extract boot2docker kernel and image
RUN 7z x /opt/boot2docker.iso boot/vmlinuz64 boot/initrd.img 

# expand core
WORKDIR $BUILD
RUN zcat $DIST/boot/core.gz | cpio -i -H newc -d

# set up ssh, set password to 'packer' for user 'tc'
WORKDIR /opt
RUN echo "/usr/local/etc/init.d/openssh start" >> $BUILD/opt/bootlocal.sh
RUN mkdir -p $BUILD/var/ssh && chown 0:50 $BUILD/var/ssh
RUN echo 'tc:packer' | chroot $BUILD chpasswd

# repack core
RUN ldconfig -r $BUILD
WORKDIR $BUILD
RUN find | cpio -o -H newc | gzip > $DIST/boot/core.gz

# remaster iso
WORKDIR /opt
RUN genisoimage -l -J -R -V TC-custom -no-emul-boot -boot-load-size 4 \
        -boot-info-table -b boot/isolinux/isolinux.bin \
        -c boot/isolinux/boot.cat -o boot2docker-install.iso $DIST
    
# write ISO and checksum to output
RUN md5sum boot2docker-install.iso > boot2docker-install.md5
CMD echo Copying boot2docker-install.iso and boot2docker-install.md5 to /output; \
        cp boot2docker-install.md5 /output; \
        cp boot2docker-install.iso /output;
