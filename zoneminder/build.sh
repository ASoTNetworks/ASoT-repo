#!/bin/bash

# This script is used for building latest Zoneminder release from source inside a Docker container.

# To build
# mkdir ~/Docker/zoneminder
# cp build.sh ~/Docker/zoneminder/
# docker run --rm --name=zoneminder-build -v ~/Docker/zoneminder:/build debian-buster /build/build.sh

# Interactive shell
# docker run -it --name=zoneminder-build -v ~/Docker/zoneminder:/build debian-buster /bin/bash

set -x
set -e

export DEBEMAIL=repo-admin@aseriesoftubez.com
export DEBFULLNAME="A Series of Tubez Networks"

echo "
deb http://mirror.aseriesoftubez.com/debian/ buster main contrib non-free
deb-src http://mirror.aseriesoftubez.com/debian/ buster main contrib non-free
deb http://mirror.aseriesoftubez.com/debian-security buster/updates main contrib non-free
deb-src http://mirror.aseriesoftubez.com/debian-security buster/updates main contrib non-free
deb http://mirror.aseriesoftubez.com/debian/ buster-updates main contrib non-free
deb-src http://mirror.aseriesoftubez.com/debian/ buster-updates main contrib non-free
" > /etc/apt/sources.list

apt update
apt -y dist-upgrade
apt -y install curl wget gnupg2 git

curl -fsSL https://repo.aseriesoftubez.com/deb/asot-repo.key | apt-key add -
echo "deb http://repo.aseriesoftubez.com/deb/zm/ buster main" >> /etc/apt/sources.list.d/asot-zm.list
apt update

get_latest_release() {
	curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
	grep '"tag_name":' |                                            # Get tag line
	sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Usage
# $ get_latest_release "creationix/nvm"
# v0.31.4
zm_version=$(get_latest_release "zoneminder/zoneminder")

if [ ! -d /build/zoneminder-$zm_version ]
then
	mkdir -p /build/zoneminder-$zm_version
fi

apt -y install sudo dh-systemd python3-sphinx apache2-dev dh-linktree cmake libx264-dev libmp4v2-dev mp4v2-utils libavdevice-dev libavcodec-dev libavformat-dev libavutil-dev libswresample-dev libavresample-dev libswscale-dev ffmpeg net-tools libbz2-dev libgcrypt20-dev libcurl4-gnutls-dev  libgnutls28-dev libjpeg-dev libjpeg62-turbo-dev default-libmysqlclient-dev libmariadb-dev-compat libpcre3-dev libpolkit-gobject-1-dev libv4l-dev libvlc-dev libdate-manip-perl libdbd-mysql-perl libphp-serialization-perl libsys-mmap-perl libssl-dev libcrypt-eksblowfish-perl libdata-entropy-perl libjs-jquery libjs-mootools devscripts htop build-essential

echo "[user]
	email = repo-admin@aseriesoftubez.com
	uame = ASoTNetworks
" > ~/.gitconfig

ldconfig
mkdir -p ~/build/zoneminder
cd ~/build/zoneminder
wget https://raw.githubusercontent.com/ZoneMinder/zoneminder/$zm_version/utils/do_debian_package.sh
chmod +x do_debian_package.sh

./do_debian_package.sh -r=$zm_version -d=buster --type=local --interactive=no 

mv *.deb /build/zoneminder-$zm_version/
