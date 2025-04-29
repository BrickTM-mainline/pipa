# ./build_boot_img.sh kernel_src_path cmdline boot_img_name modules_headers_path work_dir option
# options are: all skip_initramfs skip_modules




export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

export kernel_src_path=$1
export cmdline=$2
export boot_img_name=$3
export modules_path=$4
export headers_path="$4/usr"
export work_dir=$5
export options=$6
if [ -z "$kernel_src_path" ] || [ -z "$cmdline" ] || [ -z "$boot_img_name" ] || [ -z "$modules_path" ] || [ -z "$headers_path" ] || [ -z "$work_dir" ]; then
    echo "Usage: $0 <kernel_src_path> <cmdline> <boot_img_name> <modules_headers_path> <work_dir> <options>"
    exit 1
fi
initramfs_path="${work_dir}/initramfs"

echo
echo "#### domin kernel build script ####"
echo "kernel src: ${kernel_src_path}"
echo "cmdline: ${cmdline}"
echo "boot.img path: ${boot_img_name}"
echo "modules path: ${modules_path}"
echo "headers path: ${headers_path}"
echo "work directory: ${work_dir}"
echo "########"
echo


mkdir -p ${work_dir}
mkdir -p ${modules_path}

(cd ${kernel_src_path} && make O=out -j4)

if [ "$options" != "skip_modules" ]; then


    (cd ${kernel_src_path} && make O=out modules_install INSTALL_MOD_PATH=${modules_path})
    (cd ${kernel_src_path} && make O=out headers_install INSTALL_HDR_PATH=${headers_path})



    if [ "$options" != "skip_initramfs" ]; then
        rm -rf ${initramfs_path}/lib/modules/*
        (cd ${kernel_src_path} && make O=out modules_install INSTALL_MOD_PATH=${initramfs_path})

        # (cd ${initramfs_path} && 
        #     find lib/modules/ -name "*.ko" -print0 | while IFS= read -r -d '' ko; do
        #         modname=$(/sbin/modinfo -F name "$ko")                                             
        #         if ! grep -qxF "$modname" kept_modules.txt; then
        #             echo "Removing: $ko"
        #             rm -f "$ko"
        #         fi
        #     done
        # )

        rm -rf ${initramfs_path}/lib/modules/*/build
        echo CPIOing initramfs...
        (cd ${initramfs_path} && find . | cpio --format=newc -o > ${work_dir}/initramfs.cpio)
        echo GZipping initramfs...
        (cd ${work_dir} && gzip -9 initramfs.cpio)
    fi
fi

cat ${kernel_src_path}/out/arch/arm64/boot/Image.gz ${kernel_src_path}/out/arch/arm64/boot/dts/qcom/sm8250-xiaomi-pipa.dtb > ${work_dir}/Image.gz-dtb
echo "Creating boot.img..."
mkbootimg --kernel ${work_dir}/Image.gz-dtb --ramdisk ${work_dir}/initramfs.cpio.gz --cmdline "${cmdline}" --output ${boot_img_name}  --kernel_offset 0x8000 --ramdisk_offset 0x01000000 --tags_offset 0x100 --pagesize 4096 --base 0

if [ "$options" != "skip_modules" ]; then

    rm -rf ${modules_path}/lib/modules/*/build
    echo "Zipping modules and headers..."
    (cd ${modules_path} && zip -r ${work_dir}/modules_headers.zip)

fi
echo "Done!"

# echo "Instructions to extract modules_headers.zip:"
# echo "1. Copy ${work_dir}/modules_headers.zip to the target machine."
# echo "2. On the target machine, run: unzip ${work_dir}/modules_headers.zip -d /"
# echo "   This will extract the contents of the zip file (usr and lib) into the root directory."


