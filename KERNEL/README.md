# Description WiP

This is my Kernel, patched for NFS and Overclock.

[Kernel for MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Compiling-the-Linux-kernel-for-MiSTer)
[DE10 Nano Overclock Kernel](https://misterfpga.org/viewtopic.php?t=4320&start=120)

export ARCH=arm CROSS_COMPILE=/opt/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-

* edit .config or my template

make savedefconfig && time make -j8 LOCALVERSION="-MiSTer" zImage && make socfpga_cyclone5_de10_nano.dtb && cat arch/arm/boot/zImage arch/arm/boot/dts/socfpga_cyclone5_de10_nano.dtb > zImage_dtb
scp zImage_dtb root@mister:/media/fat/linux
