# args: ip port option
# options are: all skip_initramfs skip_modules


./build_boot_img.sh /home/domin/drivers/arch_pipa/linux "noquiet  loglevel=0 fbcon=rotate:1 root=LABEL=arch_rootfs rw" boot.img /home/domin/drivers/arch_pipa/arch/scripted_kernel/rootfs /home/domin/drivers/arch_pipa/arch/scripted_kernel/workdir $3

if [ "$3" != "skip_modules" ]; then
    ./sender.sh /home/domin/drivers/arch_pipa/arch/scripted_kernel/workdir/modules_headers.zip $1 $2
fi

