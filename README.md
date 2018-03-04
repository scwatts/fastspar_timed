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
cd /tmp/

# Clone repo and perform timed runs
git clone https://github.com/scwatts/fastspar_timed.git
cd fastspar_timed
./run.sh
```
