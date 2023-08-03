#!/bin/bash

# This script requires the VIPS software package to be installed. To install it on a Debian distribution run this command:
# sudo apt-get install libvips-tools

# check if command exists
command_exists () {
	type "$1" &> /dev/null;
}
install_vips () {
	if command_exists apt-get; then
		sudo apt-get -y update
		sudo apt-get -y -q install libvips-tools
	fi

	if ! command_exists vips; then
		echo "command vips not found"
		exit 1;
	fi
}

if ! command_exists vips ; then
  echo "command vips not found. Installing..."
	install_vips;
fi

LOG=`date +%Y%m%d_%H%M%S`"_imgconverted.log"
I=1
# Convert all images in a directory to tiff
find . -not -name "*.sh" -not -name "*.tif" -type f | while read file
do
  if [ -f "${file%.*}".tif ]; then
    echo "File ${file%.*}.tif already exists. Skipping."
    continue
  fi
  echo "*$I: Converting $file to ${file%.*}.tif" >> $LOG
  # "deflate" - ZIP (deflate) compression
  # vips im_vips2tiff "$file" "${file%.*}".tif:deflate,tile:256x256,pyramid;
  # "jpeg" - JPEG compression :## JPEG quality level;
  vips im_vips2tiff "$file" "${file%.*}".tif:jpeg:90,tile:256x256,pyramid;
  exec 1>>$LOG 2>>$LOG
  echo "=== Done ===" >> $LOG
  I=$((I+1))
  
done

# Move all tiff files to a new directory
sudo mv *.tif /var/www/iipimage-server/
