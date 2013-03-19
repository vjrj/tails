#!/bin/sh

# Note dependency on working udev

BOOT_IMAGE=/lib/live/mount/medium

dev_id_to_block_dev() {
    readlink -f /dev/block/"$*"
}

# Prints nothing if there's no parent
parent_dev() {
    parent_path=$(udevadm info --query=property --name="$1" | \
        awk -F'=' '/UDISKS_PARTITION_SLAVE/ { print $2 }')
    if [ -n "${parent_path}" ]; then
        parent_name=$(udevadm info --query=name --path="${parent_path}")
        if [ -n "${parent_name}" ]; then
            echo /dev/${parent_name}
        fi
    fi

}

boot_part() {
    boot_part_id=$(udevadm info --device-id-of-file="${BOOT_IMAGE}")
    dev_id_to_block_dev "${boot_part_id}"
}

boot_dev() {
    part=$(boot_part)
    parent=$(parent_dev ${part})
    if [ -n "${parent}" ]; then
        echo ${parent}
    else
        echo ${part}
    fi
}

dev_type() {
    udevadm info --query=property --name="$*" | \
        awk -F'=' '/ID_BUS/ { print $2 }'
}

boot_dev_type() {
    dev_type $(boot_part) 
}

is_boot_part() {
    [ "$(boot_part)" = "$1" ]
}

is_boot_dev() {
    [ "$(boot_dev)" = "$1" ]
}

is_on_boot_dev() {
    is_boot_dev "$1" || is_boot_dev "$(parent_dev "$1")"
}
