#!/bin/env bash

echo "This script comes with no warranty whatsoever. If you break your machine with it, I take no responsibility. Do not use this script without first reading and understanding the entirety of its contents!"
echo

dir=$(mktemp --directory --tmpdir isoinstaller.XXXXXXXXXX)

function goodbye {
  echo
  rm -rv "$dir"
  echo "Goodbye"
}

function errexit {
  echo
  echo "Command failed! Exiting."
  goodbye
}

trap 'goodbye' EXIT
trap 'errexit' ERR



devices=$(lsblk | grep -E '^sd' | awk '{ print "path: /dev/"$1, "size: "$4 }')
PS3="Select the device to write to: "

select device in "$devices" cancel; do case $REPLY in
  $((${#devies[@]}+2)))
    exit
    ;;
  *)
    echo
    devicename=$(echo $device | awk '{ print $2 }')
    echo "Selected $devicename"
    break
    ;;
esac; done

echo

PS3="What do you want to install? "

select option in "Memtest86" "Steam Deck Recovery Image" cancel; do case $REPLY in
  1)
    echo "Downloading Memtest86"
    file="$dir/download.iso"
    curl --output "$file" 'https://share.ryleu.me/-R5HhCjFEM8'
    hash='32684e3ef875bc785367f95bbb72b628757e492bb4de8b32961a4c76f9e08f9bb178136870e02c38283ccb639784ba541aaf6a29a5dcb88d5d90109b2b8633fb'
    if [[ ! "$(sha512sum $file)" =~ "$hash" ]]; then
      echo "Integrity check failed!"
      exit 1
    fi
    break
    ;;
  2)
    echo -n "Have you read the Steam EULA? (y/n): "
    read eula
    if [[ ! "$eula" = "y" ]]; then
      echo "Go read it."
      exit 1
    fi
    echo "Downloading Steam Deck Recovery Image"
    file="$dir/download.img"
    curl -L -o - 'https://steamdeck-images.steamos.cloud/recovery/steamdeck-repair-latest.img.bz2' | bunzip2 > "$file"
    break
    ;;
  3)
    exit
    ;;
  *)
    echo "Invalid option"
    ;;
esac; done


echo -n "Write to $devicename? This will DESTROY ALL DATA on the drive! (y/n): "
read -r doit
if [[ ! "$doit" = "y" ]]; then
  exit
fi

echo "Writing data..."
sudo dd bs=4096 status=progress if="$file" of="$devicename"
