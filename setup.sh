#!/usr/bin/env sh

chooseimg()
{
  IMG=$(find . -type f -name \*.img | fzy --prompt 'which image file? ')
  { [ -n "${IMG}" ] && [ -r "${IMG}" ] ;} || { printf "\033[31mMUST\033[0m choose an image file" && return 1 ;}
}

choosedev()
{
  DEV="/dev/$(lsblk --list | sed -n '/^sd[a-z] /p' | awk '{print $1 " " $4}' | fzy --prompt 'which device? ' | awk '{print $1}')"
  [ -e "${DEV}" ] || { printf "\033[31mMUST\033[0m choose a device" && return 1; }
}

verify()
{
  while :
    do
      _verify=$(printf "No\nYes\n" | fzy --prompt 'verify SD card? ')
      case ${_verify} in
        [Yy][Ee][Ss]) VERIFY="Y" && return 0;;
        [Nn][Oo]) return 0;;
      esac
    done
}

prompt_for_wifi()
{
  while :
    do
      _setup_wifi=$(printf "No\nYes\n" | fzy --prompt 'setup wifi? ')
      case ${_setup_wifi} in
        [Yy][Ee][Ss]) SETUP_WIFI="Y" && return 0;;
        [Nn][Oo]) return 0;;
      esac
    done
}

prompt_for_ssh()
{
  while :
    do
      _setup_wifi=$(printf "No\nYes\n" | fzy --prompt 'enable ssh for fist boot? ')
      case ${_setup_wifi} in
        [Yy][Ee][Ss]) SETUP_SSH="Y" && return 0;;
        [Nn][Oo]) return 0;;
      esac
    done
}

confirm()
{
  while :
    do
      printf "image file:\t%s" "${IMG}"
      printf "\ndevice:\t\t%s" "${DEV}"
      printf "\nsetup wifi:\t%s" "${SETUP_WIFI}"
      printf "\nenable ssh:\t%s" "${SETUP_SSH}"
      { [ -n "${VERIFY}" ] && printf "\nverify sd:\tYes" \
      || printf "\nverify sd:\tNo" ;}
      printf "\nAre you certain? "
      read -r certain
      case ${certain} in
        [Yy][Ee][Ss]) return 0;;
        [Nn][Oo]) return 1;;
        *) printf "Please answer Yes or No\n"
      esac
    done
}

flash()
{
  printf "if prompted, input your \033[31mpassword\033[0m\n"
  { [ -n "${VERIFY}" ] \
    && records=$(sudo dd bs=4M if="${IMG}" of="${DEV}" conv=fsync status=progress 2>&1 \
      | sed -n '/in$/p' | cut -d '+' -f1) ;} \
    || sudo dd bs=4M if="${IMG}" of="${DEV}" conv=fsync status=progress
  [ -n "${VERIFY}" ] \
    && sudo dd bs=4M if="${DEV}" of="${VERIFY}" count="${records}" \
    && sudo truncate --reference "${IMG}" "${VERIFY}" \
    && diff -s "${VERIFY}" "${IMG}"
}

mount_boot_partition()
{
  mkdir /tmp/boot
  mkdir /tmp/root

  sudo mount "${DEV}1" /tmp/boot
  sudo mount "${DEV}2" /tmp/root
}

init_wifi()
{
  [ -n "${SETUP_WIFI}" ] \
  && (
    cd /tmp/boot || return 1
    printf "wifi network: "
    read -r wifi_name
    stty -echo
    printf "Password: "
    read -r wifi_password
    stty echo
    printf "\n"
    printf "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n" | sudo tee wpa_supplicant.conf > /dev/null
    printf "update_config=1\n" | sudo tee -a wpa_supplicant.conf > /dev/null
    printf "country=CR\n\n" | sudo tee -a wpa_supplicant.conf > /dev/null
    wpa_passphrase "${wifi_name}" "${wifi_password}" \
    | sed '/^\s*#.*$/d;s/^}/\tkey_mgmt=WPA-PSK\n\tpriority=10\n}/' \
    | sudo tee -a wpa_supplicant.conf > /dev/null
  )
}

init_ssh()
{
  [ -n "${SETUP_SSH}" ] \
  && (
    cd /tmp/boot || return 1
    sudo touch ssh
  )
}

unmount_boot_partition()
{
  sudo umount /tmp/boot
  sudo umount /tmp/root

  rmdir /tmp/boot
  rmdir /tmp/root
}

chooseimg \
&& choosedev \
&& verify \
&& prompt_for_wifi \
&& prompt_for_ssh \
&& confirm \
&& flash \
&& mount_boot_partition \
&& init_wifi \
&& init_ssh \
&& unmount_boot_partition
