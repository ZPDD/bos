# BOS Cross Compiler (BCC)

Download [BCC](https://drive.google.com/file/d/17_uJJyXbKu9gNRwn4uxPLZb2ykV5z5Le/view?usp=sharing)

**NOTE:** 
After clicking the link above, make sure to click the download icon at the top right.

The disk image is being shared from a Google drive. Google will complain that it is too large to scan for viruses. Rest assured, there are no viruses in this, 
only the cross compiler files.

## Requirements
* At this time, the cross compiler has been setup to run on a Linux desktop based on Unbuntu. I have chosen to use Lubuntu as my Linux desktop as it is a light weight version of Ubuntu.
* The instructions below are ment to be run from a Linux terminal.

## Skill Level
* Given that we are setting up a cross compiler to be used to create programs; the assumption is the person following the steps below has some knowledge of tar, Linux, and programming.
* These instructions are not meant for end users.

## Setup
* Start your Linux desktop and launch a Terminal program.
* Building the cross compiler was based on the wiki reference material on [OSDEV] (https://wiki.osdev.org/GCC_Cross-Compiler). There are a number of dependency files needed. Use 'sudo apt install <file>' to install the following:
  * build-essentials
  * build-bison
  * flex
  * libgmp3-dev
  * libmpc-dev
  * libmpfr-dev
  * texinfo
  * libcloog-isl-dev
  * libisl-dev
* Download the cross compiler. It is recommended to put the tar file into your home directory (e.g. /home/david/bcc.tar.gz). To keep it simmple, all of the scripts and Makefiles assume that everything is in the home directory.
* Uncompress the tar file (tar xcvf bcc.tar.gz).
* 
