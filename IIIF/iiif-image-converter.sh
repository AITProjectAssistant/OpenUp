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

# Convert all images in a directory to tiff
find . -not -name "*.sh" -not -name "*.tif" -type f | while read file
do
  if [ -f "${file%.*}".tif ]; then
    echo "File ${file%.*}.tif already exists. Skipping."
    continue
  fi
  echo "Converting $file to ${file%.*}.tif"  
  vips im_vips2tiff "$file" "${file%.*}".tif:deflate,tile:256x256,pyramid;
done

# Move all tiff files to a new directory
sudo mv *.tif /var/www/iipimage-server/
