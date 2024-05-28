#!/usr/bin/bash
#

s=`sensors amdgpu-pci-0300 -j`

C=`echo $s | jq -r '."amdgpu-pci-0300".PPT.power1_average'`
M=`echo $s | jq -r '."amdgpu-pci-0300".PPT.power1_cap'`

G=$(echo "scale=5;$C/$M*100"|bc)
printf '%.1f%%' $G
