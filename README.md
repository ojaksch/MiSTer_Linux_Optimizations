# MiSTer Linux Optimizations  
These repository contains my personal tweaks and optimizations for the Linux OS running on the MiSTer device.  

These are so far:
* /etc/init.d/S10udev  
The command _udevadm settle_ in this udev startup script may raise a timeout for 3 mins for the WiFi adapter after a soft reboot. Seems to be a bug in wpa_supplicant. See [here](https://github.com/NixOS/nixpkgs/issues/107341) and [here](https://github.com/MiSTer-devel/Linux_Image_creator_MiSTer/issues/14) for a more in-depth description.
* /etc/init.d/S40network  
When using a proper DHCP and DNS solution in your network, you may notice that these services are complaining about an "unclean" re-request (and as a result getting declined) for an IP address and/or DNS entry. That's because of a dirty (re-) request from the dhcpcd daemon after a soft reboot without releasing IP address and/or DNS entry before (like after a power outage).  
See [here](https://github.com/MiSTer-devel/Linux_Image_creator_MiSTer/issues/15) for this issue at MiSTer-devel.
* /media/fat/Scripts/nfs_mount.sh  
For modified NFS aware kernels only. Is doing the same things like cifs_mount.sh, but for NFS networks.
* /KERNEL  
This is a modified Linux kernel for the MiSTer with NFS protocol included. Beware that unlinke CIFS ("mount -t cifs ...") you have to use /bin/busybox for NFS because of the missing NFS-aware mount programm. The nfs_mount.sh script above already takes this into account.  
See the Readme.md there for an in-depth description of what-and-how-to-do.
