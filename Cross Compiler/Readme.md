# BOS Cross Compiler (BCC)

Download [BCC](https://drive.google.com/file/d/17_uJJyXbKu9gNRwn4uxPLZb2ykV5z5Le/view?usp=sharing)

**NOTE:** 
After clicking the link above, make sure to click the download icon at the top right.

The disk image is being shared from a Google drive. Google will complain that it is too large to scan for viruses. Rest assured, there are no viruses in this, 
only the cross compiler files.

## Why Use a Cross Compiler
A cross compiler allows a programmer to develop on one platform (the host) and compile the code for another platform (the target). Creating a cross compiler allows the environment to be set up specifically for a target and allows for the most flexibility. It will also allow the ability to eventually port other programs to the target system. For further reading and explanation, refer to this [link](https://wiki.osdev.org/Why_do_I_need_a_Cross_Compiler%3F).

## Requirements
* At this time, the cross compiler has been setup to run on a Linux desktop based on Unbuntu. I have chosen to use Lubuntu as my Linux desktop as it is a light weight version of Ubuntu.
* The instructions below are ment to be run from a Linux terminal.

## Skill Level
* Given that we are setting up a cross compiler to be used to create programs; the assumption is the person following the steps below has some knowledge of tar, apt commands, editing text files, Linux directory structures, and programming.
* These instructions are not meant for end users.

## Setup
* Start your Linux desktop and launch a Terminal program.
* Building the cross compiler was based on the wiki reference material on [OSDEV](https://wiki.osdev.org/GCC_Cross-Compiler). There are a number of dependency files needed. Use **sudo apt install file_name** to install the following:
  * build-essential
  * bison
  * flex
  * libgmp3-dev
  * libmpc-dev
  * libmpfr-dev
  * texinfo
  * libisl-dev
  * sudo apt install build-essential wget curl git bison flex libgmp-dev libmpc-dev libmpfr-dev texinfo libisl-dev autoconf automake
* Download the cross compiler. It is recommended to put the tar file into your home directory (e.g. /home/david/bcc.tar.gz). To keep it simple, all of the scripts and Makefiles assume that everything is in the home directory.
* Uncompress the tar file (tar xvf bcc.tar.gz).
* Assuming you uncompressed the tar file in your home directory, edit the './bcc/src/build-bcc.sh' script using your favourite text editor (atom, vi, nano, etc.).
* Change line 18; **export HOME_DIR="/home/david/bcc"** to your home directory. Example; **export HOME_DIR="/home/bob/bcc"**
* *Optional*, change line 22. If you set **STEP=0**, the script will run until it is done. However, it is defaulting to **STEP=1**, this will stop the script at each configure and make command. Doing this allows you to make sure everything is building as expected and to catch any errors. 
* Run the script **./bcc/src/build-bcc.sh**. This will take approximately 30-40 minutes to complete.
* Done.

## Using BCC
Using the BCC is easy, a Makefile is provided that has a standard setup. In addition, I have provided sample programs you can reference. 

### Makefile
If you placed the cross compiler in a location that is not in your home directory; you will need to change line 8 **PREFIX = ~/bcc/bos/sysroot/bin** to the location you specified.

## Build and Compile
Once the Makefile is done:
* Create your program (e.g. hello.c). 
* Change line 11 in the Makefile to the name of your program; **NAME = hello**. 
* In a terminal execute **make** to compile the code
* Run the BOS virtual machine
* Type the command **run load_app.bin** to setup BOS to copy the program to the OS.
* Noting the IP address, run your favourite broswer and put the IP address of BOS in the address bar.
* Drag and drop the compilied program **hello.app** into the browser (NOTE the APP extension).
* In BOS, run the program; **run hello.app**.
* Done.
