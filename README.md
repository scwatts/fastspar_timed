```bash
# Set up chroot environment
sudo debootstrap xenial ubuntu_chroot http://archive.ubuntu.com/ubuntu/

# Chroot into environment
sudo chroot ubuntu_chroot/

# Add Universe repository
echo 'deb http://archive.ubuntu.com/ubuntu xenial main universe' > /etc/apt/sources.list

# Install packages
apt-get update
apt-get install -y git mercurial build-essential libarmadillo-dev libgsl-dev libopenblas-dev python-numpy python-pandas time wget ca-certificates --no-install-recommends

# Change into tmp directory
cd /var/

# Install parallel (a recent version)
wget https://ftp.gnu.org/gnu/parallel/parallel-20170522.tar.bz2
tar -jxvf parallel-20170522.tar.bz2
(cd parallel-20170522 && ./configure --prefix=/usr/ && make install -j)
mount -t proc proc /proc

# Clone repo and perform timed runs
git clone https://github.com/scwatts/fastspar_timed.git
cd fastspar_timed
./run.sh
```
