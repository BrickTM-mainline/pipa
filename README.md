# BRICK™ Arch Linux for Xiaomi Pad 6

Repository for Arch Linux ARM packages and tools optimized for the Xiaomi Pad 6 tablet.

## Available Packages

- `setup.sh` - Initial setup script that configures Arch Linux ARM on your Xiaomi Pad 6
- `scripts/kernel_crossbuild/` - Cross-compile kernel scripts that compiles and creates initial Arch Linux boot.img, also can send modules and headers through network


## Usage
### `setup.sh`
1. Download the setup script:
   ```bash
   curl -O https://raw.githubusercontent.com/rmuxnet/pipa-arch/refs/heads/main/scripts/setup.sh
   ```

2. Make it executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run as root:
   ```bash
   sudo ./setup.sh
   ```

### kernel_crossbuild
Read scripts/kernel_crossbuild/README.md
## Credits

Maintained by [rmux](https://github.com/rmuxnet) and [domin746826](https://github.com/domin746826)

BRICK™ Arch Linux project for Xiaomi Pad 6
