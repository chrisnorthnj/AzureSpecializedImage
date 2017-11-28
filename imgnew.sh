#!/bin/bash
#set -x

#----------------------------------------------------------------------------------------------------------------
#
# This script is for demonstration purposes only.  The script creates a Linux Azure Image from
# a running Linux instance.  Once the image is created, it can be used to provision a new Linux VMs
# from either the Azure GUI or CLI
#
# Chris Santaniello/Marc Strahl 11/10/2017
#
#----------------------------------------------------------------------------------------------------------------

usage() { echo "Usage: $0 [-g <resource-group>] [-n <vmname>] [-i <imagename>]" 1>&2; exit 1; }

#----------------------------------------------------------------------------------------------------------------
# Gather Input Parameters -g Resource Group, -n VM Name, -i Image Name
#----------------------------------------------------------------------------------------------------------------

while getopts ":g:n:i:" o; do
    case "${o}" in
        g)
            RESGRP=${OPTARG}
            ;;
        n)
            VMNAME=${OPTARG}
            ;;
        i)
            IMGNAME=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [ -z "${RESGRP}" ] || [ -z "${VMNAME}" ] || [ -z "${IMGNAME}" ]; then
    usage
fi

#----------------------------------------------------------------------------------------------------------------
# Create Image variables and record timestamp for storage resource naming
#----------------------------------------------------------------------------------------------------------------

TIMESTAMP=`date +"%Y%m%d%H%M%S"`

VM=`az vm show -g $RESGRP -n $VMNAME --query "{Name:name,Location:location,Size:hardwareProfile.vmSize,OSType:storageProfile.osDisk.osType,OSDisk:storageProfile.osDisk.name,OSDiskUri:storageProfile.osDisk.vhd.uri,DataDisks:storageProfile.dataDisks[].name,DataDiskUri:storageProfile.dataDisks[].vhd.uri}"`

#----------------------------------------------------------------------------------------------------------------
#  Extract relevant data points from JSON
#----------------------------------------------------------------------------------------------------------------

VMSIZE=`echo $VM | jq -c '.Size' |sed "s/\"//g" `
LOCATION=`echo $VM | jq -c '.Location' |sed "s/\"//g" `
OSTYPE=`echo $VM | jq -c '.OSType' |sed "s/\"//g" `
OSDISKNAME=`echo $VM | jq -c '.OSDisk' |sed "s/\"//g" `
OSDISKURI=`echo $VM | jq -c '.OSDiskUri' |sed "s/\"//g" | sed "s/^null$//g"`
DATADISKNAME=`echo $VM | jq -c '.DataDisks[]' |sed "s/\"//g" | tr -s '\n' ' '`
DATADISKURI=`echo $VM | jq -c '.DataDiskUri[]' |sed "s/\"//g" | tr -s '\n' ' '`
#OSDISK=$(echo $VM | jq -c '.OSDiskUri' | sed "s/[\"\s]//g" | sed "s/null//g" || echo $VM | jq -c '.OSDisk' | sed "s/\"//g")
#DATADISKS=$(echo $VM | jq -c '.DataDiskUri[]' | sed "s/\"//g" || echo $VM | jq -c '.DataDisks' | sed "s/\"//g")

if [ -z "${OSDISKURI}" ]; then
    OSDISK=${OSDISKNAME}
else
    OSDISK=${OSDISKURI}
fi

if [ -z ${DATADISKURI} ]; then
    DATADISKS=${DATADISKNAME}
else
    DATADISKS=${DATADISKURI}
Fi

#----------------------------------------------------------------------------------------------------------------
# Create Image from either Managed Disks (Names) or Unmanaged Disks (URIs pointing to VHD's
#----------------------------------------------------------------------------------------------------------------

if [ -z ${DATADISKS} ]; then
    az image create -g ${RESGRP} -n ${IMGNAME} --os-type Linux --source ${OSDISK}
else
    az image create -g ${RESGRP} -n ${IMGNAME} --os-type Linux --source ${OSDISK} --data-disk-sources ${DATADISKS}
fi

