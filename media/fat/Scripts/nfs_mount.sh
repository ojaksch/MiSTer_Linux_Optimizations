#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Copyright 20221 Oliver "RealLarry" Jaksch

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/CIFS_MiSTer

# Version 1.0 - 2021-12-29 - First commit



#=========   USER OPTIONS   =========
#You can edit these user options or make an ini file with the same
#name as the script, i.e. nfs_mount.ini, containing the same options.

#Your NFS Server, i.e. your NAS name or its IP address.
SERVER="mister-server"

# Wake up the server from above by using WOL (Wake On LAN)
WOL="yes"
SERVER_MAC="00:01:02:03:04:05"

#Optional additional mount options, when in doubt leave blank.
#MOUNT_OPTIONS="rsize=131072,wsize=131072,noatime"
MOUNT_OPTIONS="noatime"

#"true" in order to wait for the CIFS server to be reachable;
#useful when using this script at boot time.
WAIT_FOR_SERVER="true"

#"true" for automounting CIFS shares at boot time;
#it will create start/kill scripts in /etc/network/if-up.d and /etc/network/if-down.d.
MOUNT_AT_BOOT="true"



#=========CODE STARTS HERE=========

# Run this script only once after getting an IP address
[ -f /tmp/nfs_mount.lock ] && exit 1
touch /tmp/nfs_mount.lock

if [ "${WAIT_FOR_SERVER}" == "true" ]; then
    echo -n "Waiting for getting an IP address."
    until [ "$(ping -4 -c1 www.google.com &>/dev/null ; echo $?)" = "0" ]; do
	sleep 1
	echo -n "."
    done
    echo
fi

if [ "${WOL}" = "yes" ]; then
    for REP in {1..16}; do
	SERVER_MAC+=$(echo ${SERVER_MAC})
    done
    echo -n "${SERVER_MAC}" | xxd -r -u -p | socat - UDP-DATAGRAM:255.255.255.255:9,broadcast
fi

ORIGINAL_SCRIPT_PATH="$0"
if [ "$ORIGINAL_SCRIPT_PATH" == "bash" ]; then
    ORIGINAL_SCRIPT_PATH=$(ps | grep "^ *$PPID " | grep -o "[^ ]*$")
fi
INI_PATH=${ORIGINAL_SCRIPT_PATH%.*}.ini
if [ -f $INI_PATH ]; then
    eval "$(cat $INI_PATH | tr -d '\r')"
fi

if [ "${SERVER}" == "" ]; then
    echo "Please configure"
    echo "this script"
    echo "either editing"
    echo "${ORIGINAL_SCRIPT_PATH##*/}"
    echo "or making a new"
    echo "${INI_PATH##*/}"
    exit 1
fi

if ! [ "$(zgrep "CONFIG_NFS_FS=" /proc/config.gz)" = "CONFIG_NFS_FS=y" ]; then
    echo "The current Kernel doesn't support NFS."
    echo "Please update your MiSTer Linux system."
    exit 1
fi

NET_UP_SCRIPT="/etc/network/if-up.d/$(basename ${ORIGINAL_SCRIPT_PATH%.*})"
NET_DOWN_SCRIPT="/etc/network/if-down.d/$(basename ${ORIGINAL_SCRIPT_PATH%.*})"
if [ "${MOUNT_AT_BOOT}" ==  "true" ]; then
    WAIT_FOR_SERVER="true"
    if [ ! -f "${NET_UP_SCRIPT}" ] || [ ! -f "${NET_DOWN_SCRIPT}" ]; then
	mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
	[ "${RO_ROOT}" == "true" ] && mount / -o remount,rw
	echo -e "#!/bin/bash"$'\n\n'"$(realpath "$ORIGINAL_SCRIPT_PATH") &" > "${NET_UP_SCRIPT}"
	chmod +x "${NET_UP_SCRIPT}"
	echo -e "#!/bin/bash"$'\n\n'"umount -a -t nfs4" > "${NET_DOWN_SCRIPT}"
	chmod +x "${NET_DOWN_SCRIPT}"
	sync
	[ "${RO_ROOT}" == "true" ] && mount / -o remount,ro
    fi
else
    if [ -f "${NET_UP_SCRIPT}" ] || [ -f "${NET_DOWN_SCRIPT}" ]; then
	mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
	[ "${RO_ROOT}" == "true" ] && mount / -o remount,rw
	rm "${NET_UP_SCRIPT}" > /dev/null 2>&1
	rm "${NET_DOWN_SCRIPT}" > /dev/null 2>&1
	sync
	[ "${RO_ROOT}" == "true" ] && mount / -o remount,ro
    fi
fi

if [ "${WAIT_FOR_SERVER}" == "true" ]; then
    echo -n "Waiting for ${SERVER}."
    until [ "$(ping -4 -c1 ${SERVER} &>/dev/null ; echo $?)" = "0" ]; do
	sleep 1
	echo -n "."
    done
    echo
fi

SCRIPT_NAME=${ORIGINAL_SCRIPT_PATH##*/}
SCRIPT_NAME=${SCRIPT_NAME%.*}
mkdir -p "/tmp/${SCRIPT_NAME}" > /dev/null 2>&1
/bin/busybox mount -t nfs4 ${SERVER}:/media/soft/emu /tmp/${SCRIPT_NAME} -o ${MOUNT_OPTIONS}
IFS=$'\n'
for LDIR in $(ls /tmp/${SCRIPT_NAME}); do
    if [ -d "/media/fat/${LDIR}" ] && [ -d "/tmp/${SCRIPT_NAME}/${LDIR}" ] && ! [ $(mount | grep "/media/fat/${LDIR} type nfs4") ]; then
        echo "Mounting ${LDIR}"
        mount -o bind "/tmp/${SCRIPT_NAME}/${LDIR}" "/media/fat/${LDIR}"
    fi
done

echo "Done!"
exit 0
