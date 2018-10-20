#!/bin/bash

WORKDIR=temp
rm -rf $WORKDIR
mkdir $WORKDIR

#####[ Building name of new iso ]#####
ISO_SRC=$( find -name '*.iso' | grep -v AUTO | head -n 1 )
ISO_PREFIX=$( echo "$ISO_SRC" | sed 's/.iso//' )
ISO_TARGET=$( echo "$ISO_PREFIX-AUTO.iso" )

# check architecture (amd64 and i386 only...)
if [ `echo $ISO_PREFIX | grep -c "i386" ` -gt 0 ]; then
	architecture="install.386";
elif [ `echo $ISO_PREFIX | grep -c "amd64" ` -gt 0 ]; then
	architecture="install.amd";
else
	echo "ERROR: Architecture not supported."; exit 1
fi

#####[ Extracting files from iso ]#####
xorriso -osirrox on -dev $ISO_SRC \
	-extract "/isolinux/isolinux.cfg" $WORKDIR/isolinux.cfg \
	-extract "/isolinux/txt.cfg" $WORKDIR/txt.cfg \
	-extract "/md5sum.txt" $WORKDIR/md5sum.txt \
	-extract "/${architecture}/gtk/initrd.gz" $WORKDIR/initrd.gz
#####[ Adding preseed to initrd ]#####
cp preseed.cfg $WORKDIR/
cd $WORKDIR
gunzip initrd.gz
chmod +w initrd
echo "preseed.cfg" | cpio -o -H newc -A -F initrd
gzip initrd

#####[ Changing default boot menu timeout ]#####
sed -i 's/timeout 0/timeout 1/' isolinux.cfg

#####[ Changing default boot menu]#####
cat > txt.cfg <<- EOF
default install
label install
        menu label ^Install AUTO VGH
        menu default
        kernel /${architecture}/vmlinuz
        append auto=true vga=788 preseed/file=/cdrom/preseed.cfg initrd=/${architecture}/initrd.gz -- quiet
EOF

#####[ Fixing MD5 ]#####
fixSum initrd.gz ./${installdir}/gtk/initrd.gz
fixSum isolinux.cfg ./isolinux/isolinux.cfg
fixSum txt.cfg ./isolinux/txt.cfg
fixSum preseed.cfg ./preseed.cfg
cd ..

#####[ Writing new iso ]#####
rm $ISO_TARGET
xorriso -indev $ISO_SRC \
	-map  $WORKDIR/isolinux.cfg "/isolinux/isolinux.cfg" \
	-map  $WORKDIR/txt.cfg "/isolinux/txt.cfg" \
	-map  $WORKDIR/md5sum.txt "/md5sum.txt" \
	-map  $WORKDIR/initrd.gz "/${architecture}/gtk/initrd.gz" \
	-map  $WORKDIR/preseed.cfg "/preseed.cfg" \
	-boot_image isolinux dir=/isolinux \
	-outdev $ISO_TARGET

rm -rf $WORKDIR
#rm $ISO_SRC
#xorriso
