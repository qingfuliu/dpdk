#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# println echos string
function println() {
  echo -e "$1"
}
# errorln echos i red color
function errorln() {
  println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
  println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
  println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
  println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
  errorln "$1"
  exit 1
}

function check_eth_type(){ 
    infoln "checking $1's type ..." 
    declare check_str
    check_str=$(ethtool -i "$1" | sed -n '1p')
    OLD_IFS="$IFS"
    IFS=": "
    read -ra  type_map <<< "${check_str}"
    IFS="$OLD_IFS"
    
    if [[ ${#type_map[@]} != 2 ]] || [[ ${type_map[1]} != "vmxnet3" ]] ;
    then
        fatalln "$1's type is  ${type_map[1]},error"
    else
        successln "$1's type is  ${type_map[1]},ok"
    fi
    return 0
} 

function mount_igb_uio(){ 
    infoln "checking if igc_io is mounted ..." 
    declare check_str
    check_str=$(lsmod | grep igb_uio)
    if [ -z "$check_str" ]
    then
      infoln "Igc_io has not been mounted yet, mount it"
      modprobe uio
      insmod /usr/local/dpdk-eth/linux/igb_uio/igb_uio.ko intr_mode=legacy
    fi
    
    check_str=$(lsmod | grep igb_uio)
    if [ -z "$check_str" ]
    then
      fatalln "Igc_io mounting failed, error"    
    fi

    successln "igc_io has been mounted,ok"

}

function bind_eth() {

    eth_name=${1}
    
    if ! ifconfig "${eth_name}" down; then
        fatalln "failed to colse ${eth_name},error"
    fi

    if ! dpdk-devbind.py -b igb_uio "${eth_list[i]}";then
        fatalln "failed to bind ${eth_name},error"
    fi
    successln "Successfully bind ${eth_name}, ok"    
    return 0
}

function print_what_should_be_done_next(){
    infoln "****************************************" 
    infoln "all automation steps have been completed"
    infoln "****************************************" 
    infoln "If you want to confirm whether the execution was successful, please execute the following command:"
    infoln "cd dpdk/examples/l2fwd"
    infoln "make"
    infoln "./build/l2fwd -l 0-1 -- -p 0x3 -T 1"
    infoln "****************************************" 
    infoln "You will see the following output:"
    infoln "Port statistics ===================================="
    infoln "Statistics for port 0 ------------------------------"
    infoln "Packets sent:                        0"
    infoln "Packets received:                    0"
    infoln "Packets dropped:                     0"
    infoln "Statistics for port 1 ------------------------------"
    infoln "Packets sent:                        0"
    infoln "Packets received:                    0"
    infoln "Packets dropped:                     0"
    infoln "Aggregate statistics ==============================="
    infoln "Total packets sent:                  0"
    infoln "Total packets received:              0"
    infoln "Total packets dropped:               0"
    infoln "===================================================="
    infoln "****************************************" 
    infoln "Otherwise, check the script to identify the problem"
    return 0
}

eth_list=(ens192 ens224)



for((i=0;i<${#eth_list[@]};i++))
do
    check_eth_type "${eth_list[i]}"
done

mount_igb_uio


for((i=0;i<${#eth_list[@]};i++))
do
    bind_eth "${eth_list[i]}"
done

print_what_should_be_done_next

