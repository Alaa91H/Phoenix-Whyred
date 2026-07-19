### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## Adapted for Phoenix-Whyred 7.0.9 (sdm660-mainline)

### AnyKernel setup
# begin properties
properties() { '
kernel.string=Phoenix-Whyred 7.0.9
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=whyred
device.name2=Redmi Note 5 Pro
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot;

# begin ramdisk changes
# (none required for pure Image flash on whyred when using Magisk/KernelSU-friendly AK3)
# end ramdisk changes

write_boot;
## end boot install
