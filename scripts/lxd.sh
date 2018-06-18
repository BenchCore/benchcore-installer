apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7635B973

sudo tee -a /etc/apt/sources.list.d/lxd.list << EOF
deb http://ppa.launchpad.net/ubuntu-lxc/lxd-stable/ubuntu xenial main
deb-src http://ppa.launchpad.net/ubuntu-lxc/lxd-stable/ubuntu xenial main
EOF

apt-get update
apt-get upgrade -y

apt-get install -y build-essential libssl-dev zlib1g-dev libncurses5-dev

# Determine versions
arch="$(uname -m)"
release="$(uname -r)"
upstream="${release%%-*}"
local="${release#*-}"

# Get kernel sources
mkdir -p /usr/src
wget -O "/usr/src/linux-${upstream}.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${upstream}.tar.xz"
tar xf "/usr/src/linux-${upstream}.tar.xz" -C /usr/src/
ln -fns "/usr/src/linux-${upstream}" /usr/src/linux
ln -fns "/usr/src/linux-${upstream}" "/lib/modules/${release}/build"

# Prepare kernel
zcat /proc/config.gz > /usr/src/linux/.config
printf 'CONFIG_LOCALVERSION="%s"\nCONFIG_CROSS_COMPILE=""\n' "${local:+-$local}" >> /usr/src/linux/.config
wget -O /usr/src/linux/Module.symvers "http://mirror.scaleway.com/kernel/${arch}/${release}/Module.symvers"
make -C /usr/src/linux prepare modules_prepare

# Install ZFS
apt-get install -y uuid-dev dh-autoreconf
cd /usr/src/
wget https://github.com/zfsonlinux/zfs/releases/download/zfs-0.6.5.9/spl-0.6.5.9.tar.gz
tar -zxf spl-0.6.5.9.tar.gz
cd spl-0.6.5.9
./autogen.sh; ./configure; make; make install

cd /usr/src
wget https://github.com/zfsonlinux/zfs/releases/download/zfs-0.6.5.9/zfs-0.6.5.9.tar.gz
tar -xvf zfs-0.6.5.9.tar.gz
cd zfs-0.6.5.9
./autogen.sh; ./configure; make; make install
depmod -a
ldconfig
modprobe zfs || exit 1
apt-get install -y zfsutils-linux

# Install LXD
apt-get install -y lxd
