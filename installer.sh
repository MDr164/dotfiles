#/bin/sh

export FOREGROUND=212
export BORDER="normal"
export BORDER_FOREGROUND=240
export ALIGN="center"
export WIDTH=60
export GUM_SPIN_SHOW_OUTPUT=1

clear
gum style "Custom Arch Install Script by MDr164"
gum confirm "Are you ready to start?" || exit 0

clear
gum style "Choose which stage we are in"
STAGE=$(gum choose bootstrap chroot)

if [ $STAGE == "bootstrap" ] then
    clear
    gum style "Choose which root filesystem type you want"
    FS_TYPE=$(gum choose F2FS EXT4)

    clear
    gum style "Choose the disk to install to"
    AVAILABLE_DISKS=$(lsblk -dnplo NAME)
    DISK=$(gum choose $AVAILABLE_DISKS)

    clear
    gum style "Lastly your hostname for the device"
    HOST=$(gum input --placeholder "hostname")

    clear
    gum style "Gotcha, so shall we nuke the drive now?"
    gum confirm "This will wipe $DISK" || exit 0

    clear
    gum style "Installing the system now ~(@_@~)"
    gum spin --title "Preparing to format disk..." sleep 3

    # Create partition table
    sgdisk -G $DISK
    sgdisk -n 1:2048:+500M -c 1:"EFI" -t 1:ef00 $DISK
    sgdisk -n 2::+2G -c 2:"XBOOTLDR" -t 2:ea00 $DISK
    sgdisk -n 3:: -c 3:"OS" -t 3:8309 $DISK
    
    # Create boot partitions
    mkfs.vfat -F 32 -n EFI ${DISK}1
    mkfs.vfat -F 32 -n XBOOTLDR ${DISK}2

    # Create os partition and logical volumes
    cryptsetup -S 1 --label OS luksFormat ${DISK}3
    cryptsetup luksOpen ${DISK}3 enc
    pvcreate /dev/mapper/enc
    vgcreate vg0 /dev/mapper/enc
    lvcreate -L 2G vg0 -n SWAP
    lvcreate -L 100M vg0 -n VERITY_A
    lvcreate -L 5G vg0 -n ROOT_A
    lvcreate -L 100M vg0 -n VERITY_B
    lvcreate -L 5G vg0 -n ROOT_B
    lvcreate -L 10G vg0 -n VAR
    lvcreate -l 100%FREE vg0 -n HOME

    # Create swap space
    mkswap -L SWAP /dev/vg0/SWAP
    swapon /dev/vg0/SWAP

    # Create partitions based on selected FS_TYPE and mount them
    if [ $FS_TYPE == "F2FS" ] then
        mkfs.f2fs -l HOME -O extra_attr,inode_checksum,sb_checksum,compression,encrypt /dev/vg0/HOME
        mkfs.f2fs -l VAR -O extra_attr,inode_checksum,sb_checksum,compression /dev/vg0/VAR
        mkfs.f2fs -l ROOT_A -O extra_attr,inode_checksum,sb_checksum,compression /dev/vg0/ROOT_A
        mkfs.f2fs -l ROOT_B -O extra_attr,inode_checksum,sb_checksum,compression /dev/vg0/ROOT_B
        mount -t f2fs -o compress_algorithm=zstd,compress_chksum,atgc,gc_merge,lazytime /dev/vg0/ROOT_A /mnt
        mkdir /mnt/{boot,home,var}
        mount -t f2fs -o compress_algorithm=zstd,compress_chksum,atgc,gc_merge,lazytime /dev/vg0/VAR /mnt/var
        mount -t f2fs -o compress_algorithm=zstd,compress_chksum,atgc,gc_merge,lazytime /dev/vg0/HOME /mnt/home
    elif [ $FS_TYPE == "EXT4" ] then
        mkfs.ext4 -L HOME -O encrypt /dev/vg0/HOME
        mkfs.ext4 -L VAR -O encrypt /dev/vg0/VAR
        mkfs.ext4 -L ROOT_A -O encrypt /dev/vg0/ROOT_A
        mkfs.ext4 -L ROOT_B -O encrypt /dev/vg0/ROOT_B
        mount -t ext4 /dev/vg0/ROOT_A /mnt
        mkdir /mnt/{boot,home,var}
        mount -t ext4 /dev/vg0/VAR /mnt/var
        mount -t ext4 /dev/vg0/HOME /mnt/home
    fi # FS_TYPE select
    mount -t vfat LABEL=XBOOTLDR /mnt/boot
    mkdir /mnt/boot/efi
    mount -t vfat LABEL=EFI /mnt/boot/efi

    # Bootstrap Arch Linux
    gum spin --title "Installing packages..." pacstrap -K /mnt base linux-hardened linux-firmware f2fs-tools cryptsetup lvm2 booster iwd efibootmgr efitools sbsigntools tpm2-tss apparmor nix gum

    # Create some final files before ending the bootstrap stage
    gum spin --title "Preparing a few system files..." sleep 3
    genfstab -U /mnt >> /mnt/etc/fstab
    ln -sf /mnt/share/zoneinfo/Europe/Amsterdam /mnt/etc/localtime
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
    echo "KEYMAP=de-latin1" > /mnt/etc/vconsole.conf
    echo $HOST > /mnt/etc/hostname
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen

elif [ $STAGE == "chroot" ] then
    clear
    gum style "Almost done! Now let us configure the remaining parts"
    gum spin "Preparing to configure..." sleep 3
    hwclock --systohc
    locale-gen

    #TODO: UKI generation

    clear
    gum style "Type in your user name"
    USER=$(gum input --placeholder "username")

    # Create user using systemd-homed
    homectl create $USER --storage=fscrypt --fido2-device=auto --fido2-with-user-presence=yes --recovery-key=yes --member-of=wheel

    #TODO: Figure out what else we're missing

fi # STAGE select
