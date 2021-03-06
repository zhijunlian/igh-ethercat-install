#/bin/bash 
export KERNEL_VERSION="4.4.0-140-lowlatency"
export MASTER_DEVICE="\
MASTER0_DEVICE=\"00:15:17:de:77:ee\"\n\
MASTER1_DEVICE=\"00:15:17:de:77:ef\"\n\
"
export ETHERLAB_PREFIX="/opt/etherlab"
export DRIVER_TYPE="e1000e"

set -ex &&
sudo apt-get install -y build-essential &&
sudo apt-get install -y linux-headers-$KERNEL_VERSION &&
sudo apt-get install -y mercurial autoconf autogen libtool make &&
export ETHERLAB_DIR="etherlabmaster-code" 
if [ ! -d $ETHERLAB_DIR ]; then
    hg clone http://hg.code.sf.net/p/etherlabmaster/code "$ETHERLAB_DIR" -r stable-1.5 
fi
cd $ETHERLAB_DIR 
./bootstrap &&
./configure --prefix=$ETHERLAB_PREFIX --with-linux-dir=/usr/src/linux-headers-$KERNEL_VERSION --enable-cycles --enable-hrtimer --enable-8139too=no --enable-r8169=yes --enable-e1000e=yes --enable-eoe=no &&
make -j$(nproc) &&
make all modules &&
sudo make install &&
sudo make modules_install &&
sudo mkdir -p /etc/sysconfig &&
echo -e $MASTER_DEVICE | sudo tee $ETHERLAB_PREFIX/etc/ethercat.conf &&
echo DEVICE_MODULES=\"$DRIVER_TYPE\" | sudo tee -a $ETHERLAB_PREFIX/etc/ethercat.conf &&
sudo cp $ETHERLAB_PREFIX/etc/ethercat.conf $ETHERLAB_PREFIX/etc/sysconfig/ethercat &&
sudo cp $ETHERLAB_PREFIX/etc/sysconfig/ethercat /etc/sysconfig &&
sudo depmod &&
echo KERNEL==\"EtherCAT[0-9]\", MODE=\"0777\" | sudo tee /etc/udev/rules.d/99-ethercat.rules &&
sudo udevadm control --reload-rules &&
echo $ETHERLAB_PREFIX/lib | sudo tee -a /etc/ld.so.conf &&
sudo ldconfig &&
echo `echo $USER` hard rtprio 99 | sudo tee -a /etc/security/limits.conf &&
sudo cp $ETHERLAB_PREFIX/bin/ethercat /usr/local/bin &&
sudo $ETHERLAB_PREFIX/etc/init.d/ethercat restart &&
sleep 1
set +x # stop show the command that will execute
echo -e "\n>>>>>>>>>> Test <<<<<<<<<<\n"
ethercat master
