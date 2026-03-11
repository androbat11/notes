#!/bin/bash

# Module 1: The Mount Command - Concepts & Syntax
# Run this with: bash 01_mount_concepts.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function check_answer() {
    if [[ "$1" == "$2" ]]; then
        echo -e "${GREEN}Correct!${NC}"
        return 0
    else
        echo -e "${RED}Incorrect. Try again.${NC}"
        return 1
    fi
}

echo "--- Linux Mounting: Exercise 1/5 ---"
echo "What is the command to mount a block device '/dev/sdb1' to the folder '/mnt/data'?"
read -p "> " user_cmd
check_answer "$user_cmd" "mount /dev/sdb1 /mnt/data"

echo -e "\n--- Linux Mounting: Exercise 2/5 ---"
echo "You want to unmount '/mnt/data'. What is the command? (Hint: It is NOT 'unmount')"
read -p "> " user_cmd
check_answer "$user_cmd" "umount /mnt/data"

echo -e "\n--- Linux Mounting: Exercise 3/5 ---"
echo "Which directory in Linux usually contains 'Block Device' files (like sda1, sdb1)?"
read -p "> " user_path
check_answer "$user_path" "/dev"

echo -e "\n--- Linux Mounting: Exercise 4/5 ---"
echo "If you mount a device onto a folder that ALREADY has files, what happens to those files?"
echo "A) They are deleted."
echo "B) They are hidden until the device is unmounted."
echo "C) They are merged with the new device files."
read -p "> " user_choice
check_answer "$user_choice" "B"

echo -e "\n--- Linux Mounting: Exercise 5/5 ---"
echo "Which system configuration file stores persistent mount points for boot time?"
read -p "> " user_file
check_answer "$user_file" "/etc/fstab"

echo -e "\n--- Module Complete! ---"
