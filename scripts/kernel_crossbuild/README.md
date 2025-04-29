# kernel_crossbuild

This directory contains tools for building the kernel image and initramfs for the Xiaomi Pad 6 (pipa), as well as preparing and transferring kernel modules and headers.

## Contents

- **make_all.sh**  
  Script automating the entire process of building the kernel, preparing the modules/headers package, and sending it to the tablet.  Most of the time you will only use this one and receive.sh.

  Usage:
  ```
  ./make_all.sh <tablet_IP> <port> <option>
  ```
  - `<tablet_IP>` – IP address of the Pipa tablet in the local network
  - `<port>` – port on which the `receive.sh` script is listening on the tablet
  - `<option>` - Build mode, normally you should use `all`. No option means `all`.

- **build_boot_img.sh**  
  Main script for building the kernel image (`boot.img`), initramfs, and a package with kernel modules and headers (`modules_headers.zip`).  
  Arguments:
  1. Path to the kernel sources
  2. Kernel cmdline parameters
  3. Output boot.img filename
  4. Path to the directory for modules and headers - any directory is fine, if you want to install stuff directly to rootfs, then mount rootfs and put here that rootfs path.
  5. Working directory - any empty directory
  6. Options (`all`, `skip_initramfs`, `skip_modules`)


- **sender.sh**  
  Script for sending a file (e.g., `modules_headers.zip`) to the tablet over the network. You won't use that file

- **receive.sh**  
  Script that must be run on the tablet before sending files. It receives the file and saves it locally.

- **workdir/**  
  Working directory for temporary files, initramfs, etc. Contains initramfs skeleton

## Usage Instructions
0. **On the host computer**  
   - Install cross-compile kernel dependences
   - Download your desired kernel (recommended: [github.com/pipa-project/linux, branch domin746826/dev](https://github.com/pipa-project/linux/tree/domin746826/dev))  
   - Learn how kernel to compile kernel manually  
   - Configure your kernel, example config in the root of this repo: pipa_kernel_config
   - Try compiling kernel manually

1. **On the tablet**  
   Before compile, if you haven't chose `skip_modules` option, run the `receive.sh` script on the tablet:
   ```
   ./receive.sh <port>
   ```
   where `<port>` is the port number the script will listen on (e.g., 1234). Script will output tablet IP and port (for confirmation) and will wait for modules.

2. **On the host computer**  
   Edit Run the `make_all.sh` script, providing the tablet's IP address and the same port:
   ```
   ./make_all.sh <tablet_IP> <port> <option>
   ```
   The script will build the kernel, prepare the modules and headers package, and send it to the tablet.
   
   **What is `<option>` for?**
   - You can choose `all`, `skip_initramfs` or `skip_modules`. 
      - `all` - Standard full build, together with uploading modules and headers to tablet and receive.sh 
      - `skip_initramfs` - Skip updating initramfs, useful if you work on one specific driver/module which isn't used in initramfs, saves time
      - `skip_modules` - Does what `skip_initramfs` do, and doesn't upload modules. Shouldn't be used unless you're working on something built in into kernel or debugging cmdline.

3. **Next steps**  
   After file is transfered, reboot immediately to fastboot and flash your newly built boot.img. 

   **Have fun!**

## Notes

- Before running, make sure you have all required tools installed (`mkbootimg`, `zip`, `cpio`, `gzip`, `wget`, etc.).
- The scripts assume a specific directory structure and the presence of kernel sources in the expected location.
- You can modify default paths and parameters in the script files.
