# FastSpar and SparCC performance comparison
The scripts in this repository compare the performance of FastSpar and SparCC. The high level description of processes taken here is:
1. Set up a clean and reproducible run environment using `chroot`
2. Resolve dependencies for FastSpar and SparCC
3. Provision the FastSpar and SparCC software
4. Generate random subsets of the American Gut OTU table
5. Run FastSpar and SparCC on each dataset, profiling walltime and memory usage
6. Plot results

The repository containing a less detailed comparison of all SparCC implementations can be found [here](https://github.com/scwatts/sparcc_implementation_comparison).

# Performing this analysis
## Requirements
There are a few requirements to run this analysis:
* A modern computer with amd64 architecture running GNU/Linux
* Run commands as a supseruser (e.g. using `sudo`)
* Have `debootstrap` installed
* An internet connection

## Running
To run this analysis, a `chroot` environment is first required. The following commands will create a Ubuntu 16.04 (Xenial) `chroot` in the current working directory named `ubuntu_chroot` and run an interactive shell with it:
```bash
# Set up chroot environment
sudo debootstrap xenial ubuntu_chroot http://archive.ubuntu.com/ubuntu/

# Chroot into environment
sudo chroot ubuntu_chroot/
```

Next the appropriate dependencies must be installed within the `chroot`:
```bash
# Add Universe repository
echo 'deb http://archive.ubuntu.com/ubuntu xenial main universe' > /etc/apt/sources.list

# Install packages
apt-get update
apt-get install -y git mercurial autoconf autoconf-archive automake parallel build-essential libgsl-dev libopenblas-dev python-numpy python-pandas time wget r-base-core ca-certificates --no-install-recommends
```

The latest version of Armadillo to be compiled:
```bash
apt-get install -y cmake libopenblas-dev liblapack-dev libarpack2-dev
wget http://sourceforge.net/projects/arma/files/armadillo-8.500.1.tar.xz
tar -Jxvf armadillo-8.500.1.tar.xz && cd armadillo-8.500.1/
cmake . && make install -j
cd ../ && rm -r armadillo-8.500.1{/,.tar.xz}
```

Finally this repository can be cloned and the analysis run:
```bash
# Change into tmp directory
cd /tmp/

# Clone repo and perform timed runs
git clone https://github.com/scwatts/fastspar_timed.git
cd fastspar_timed
./run.sh
```

Note: some processes are parallised and are set to uses several threads. If your machine has less than the specified number, you'll need to edit the run.sh script to specify the number of threads to use.
