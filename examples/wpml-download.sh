#!/bin/bash
#
# Get WPML releases.
#

# Start from an empty directory
#
#     ../wpml-download.sh


echo "# List downloads"
echo "https://wpml.org/account/"
echo "https://wpml.org/account/downloads/"
echo

echo "# Get download URL-s"
echo "jQuery('.download-button').each(function(){ console.log(jQuery(this).attr('href')); });"
echo

read -s -p "Press any key ..." -n 1

echo "# Copy&paste URL-s from console output WITH quotes"
sleep 5
editor wpml.url
echo

echo "# Downloading plugins ..."
if [ -f wpml.url ]; then
    # Remove quotes
    tr -d '"' < wpml.url \
        | wget -nv -N --content-disposition -i -

    # Fix filenames
    find -type f -name "*.zip?*" \
        | while read -r DISPOSITION; do
            mv -v "$DISPOSITION" "${DISPOSITION%%\?*}"
        done
fi
echo

echo "OK."
