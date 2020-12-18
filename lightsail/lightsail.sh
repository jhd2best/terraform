#!/bin/bash

shard="s0"
indexes=( 12 16 )

region="us-west-2"

profile="mainnet"
blueprint="amazon_linux_2"
bundle="large_2_0"
key="harmony-node"

function usage()
{
   local me=$(basename $0)
   cat<<-EOU
$me [options] action

Options:
   -h                print this help
   -s shard          specify shard id (default: $shard)
   -i first_index    specify the first index of the blskey in this instance, delimited by ,
   -r region         specify the region (default: $region)

Actions:
   create            create lightsail instances
   port              manage public ports
   ip                list all ip addresses of lightsail instances

Examples:
   $me -s s0 -i 12,16 create
   $me -s s0 -i 12,16 port
   $me -s s0 -i 12,16 ip

EOU
   exit 0
}

function create()
{
   for i in ${indexes[@]}; do
      aws --profile $profile --region $region \
      lightsail create-instances \
      --availability-zone "${region}b" \
      --instance-name "mainnet.$shard.$i" \
      --blueprint-id $blueprint \
      --bundle-id $bundle \
      --key-pair-name $key \
      --tags "key=Shard,value=$shard"
   done
}

function open_port()
{
   for i in ${indexes[@]}; do
      aws --profile $profile --region $region \
      lightsail close-instance-public-ports \
      --instance-name "mainnet.$shard.$i" \
      --port-info "protocol=TCP,fromPort=22,toPort=22"

      aws --profile $profile --region $region \
      lightsail close-instance-public-ports \
      --instance-name "mainnet.$shard.$i" \
      --port-info "protocol=TCP,fromPort=80,toPort=80"
   done

   for i in ${indexes[@]}; do
      aws --profile $profile --region $region \
      lightsail open-instance-public-ports \
      --instance-name "mainnet.$shard.$i" \
      --port-info "protocol=TCP,fromPort=6000,toPort=6000"

      aws --profile $profile --region $region \
      lightsail open-instance-public-ports \
      --instance-name "mainnet.$shard.$i" \
      --port-info "protocol=TCP,fromPort=9000,toPort=9000"

      aws --profile $profile --region $region \
      lightsail open-instance-public-ports \
      --instance-name "mainnet.$shard.$i" \
      --port-info "protocol=TCP,fromPort=6060,toPort=6060,cidrs=54.153.42.130/32"

      aws --profile $profile --region $region \
      lightsail open-instance-public-ports \
      --instance-name "mainnet.$shard.$i" \
      --port-info "protocol=TCP,fromPort=9100,toPort=9100,cidrs=13.56.179.164/32"

      aws --profile $profile --region $region \
      lightsail open-instance-public-ports \
      --instance-name "mainnet.$shard.$i" \
      --port-info "protocol=TCP,fromPort=9500,toPort=9500,cidrs=13.56.179.164/32,52.8.205.132/32,54.153.42.130/32"

      aws --profile $profile --region $region \
      lightsail open-instance-public-ports \
      --instance-name "mainnet.$shard.$i" \
      --port-info "protocol=TCP,fromPort=22,toPort=22,cidrs=54.153.42.130/32, 13.56.179.164/32"

   done
}

function getip()
{
   for i in ${indexes[@]}; do
      sip=$( aws --profile $profile --region $region \
      lightsail get-static-ip \
      --static-ip-name "sip.$shard.$i" | jq -r .staticIp.ipAddress)

      if [ -z "$sip" ]; then
         aws --profile $profile --region $region \
         lightsail allocate-static-ip \
         --static-ip-name "sip.$shard.$i"
         sleep 3
         sip=$(aws --profile $profile --region $region \
         lightsail get-static-ip \
         --static-ip-name "sip.$shard.$i" | jq -r .staticIp.ipAddress)
      else
         echo $sip
         continue
      fi

      aws --profile $profile --region $region \
      lightsail attach-static-ip \
      --static-ip-name "sip.$shard.$i" \
      --instance-name "mainnet.$shard.$i"

      echo $sip
   done
}

while getopts ":hs:i:r:" opt; do
   case $opt in
      s) shard=$OPTARG;;
      i) index=$OPTARG;;
      r) region=$OPTARG;;
      *) usage;;
   esac
done

shift $(( OPTIND - 1 ))

if [ -n "$index" ]; then
   indexes=( $(echo $index | tr , " ") )
fi

action=$1

case $action in
   create) create ;;
   port) open_port ;;
   ip) getip ;;
esac

