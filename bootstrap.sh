#!/bin/bash
# This file will be run as root. It installs Octave for Ubuntu. 

# add octave repository
add-apt-repository ppa:octave/stable

# rebuild repository list 
apt-get update

# install -y octave 
apt install -y texinfo
apt install -y gnuplot
apt install -y octave
apt install -y liboctave-dev
apt install -y octave-info

 
# cut and paste uncommented on Mac side, or add to your .profile on the VM (run pico .profile)
# export LANG="en_US.utf8"
# export LANGUAGE="en_US.utf8"
# export LC_ALL="en_US.utf8"

# launch octave with "octave" 
# test X11 with “sombrero(30)” in Octave.