#!/usr/bin/env bash

SSH='ssh -i ~/.ssh/harmony-node.pem -o StrictHostKeyChecking=no -o LogLevel=error -o ConnectTimeout=5 -o GlobalKnownHostsFile=/dev/null'
HARMONYDB=harmony.go

function usage
{
   local me=$(basename $0)
   cat<<EOT
Usage: $me blskey_index
This is a wrapper script used to manage/launch the Azure nodes using terraform scripts.
PREREQUISITE:
* this script can only be run on devop.hmny.io host.
* make sure you have set AZURE_CLIENT_SECRET environment variable.
OPTIONS:
   -h                               print this help message
   -S                               enabled state pruning for the node (default: false)
   -r <region>                      specify the region (default: $REG)
                                    supported region: $(echo ${REGIONS[@]} | tr " " ,)
COMMANDS:
   new [list of index]              list of blskey index
   rclone [list of ip]              list of IP addresses to run rclone 
   wait [list of ip]                list of IP addresses to wait until rclone finished, check every minute
   uptime [list of ip]              list of IP addresses to update uptime robot, will generate uptimerobot.sh cli
EXAMPLES:
   $me new 308
   $me newmk 20 40 80
   $me rclone 1.2.3.4
   $me wait 1.2.3.4 2.2.2.2
   $me uptime 1.2.3.4 2.2.2.2
EOT

   exit 0
}

function init_check
{
   if [ -z "$ARM_CLIENT_ID" ]; then
      echo please specify the client_id variable
      echo export ARM_CLIENT_ID=\"your azure client id\"
      exit 1
   fi

   if [ -z "$ARM_CLIENT_SECRET" ]; then
      echo please specify the client_secret variable
      echo export ARM_CLIENT_SECRET=\"your azure client secret\"
      exit 1
   fi

   if [ -z "$ARM_TENANT_ID" ]; then
      echo please specify the tenant_id variable
      echo export ARM_TENANT_ID=\"your azure tenant id\"
      exit 1
   fi

   if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
      echo please specify the subscription_id variable
      echo export ARM_SUBSCRIPTION_ID=\"your azure subscription id\"
      exit 1
   fi
}

function get_regions
{
   i=0
   while read -r line; do
      read location up <<< $line
      if [ $up == "UP" ]; then
         alllocations[$i]=$location
         (( i++ ))
      fi
   done < r.list
}

function _do_launch_one
{
   local index=$1
   local name=$2

   if [ -z "$index" ]; then
      echo blskey_index is empty, ignoring
      return
   fi

   if [[ $index -lt 0 || $index -ge 360 ]]; then
      echo index: $index is out of bound, ignoring
      return
   fi

   if [ "$REG" == "random" ]; then
      REG=${alllocations[$RANDOM % ${#alllocations[@]}]}
   fi

   shard=$(( $index % 4 ))

   terraform apply -var "blskey_index=$index" -var "shard=$shard" -var "location=$REG" -var "name=$name"  -auto-approve || return
   sleep 3
   IP=$(terraform output | grep 'public_ip = ' | awk -F= ' { print $2 } ' | tr -d ' ')
   sleep 1
   mv -f terraform.tfstate states/terraform-$name.tfstate
}

function new_instance
{
   indexes=$@
   rm -f ip.txt
   for i in $indexes; do
      _do_launch_one $i "s${shard}-a2"
      echo $IP >> ip.txt
   done
}

# new host with multiple bls keys
function do_new_mk
{
   indexes=( $@ )
   shard=-1
   for idx in ${indexes[@]}; do
      idx_shard=$(( $idx % 4 ))
      if [ $shard == -1 ]; then
         shard=$idx_shard
      else
         if [ $shard != $idx_shard ]; then
            errexit "shard: $shard should be identical. $idx is in shard $idx_shard."
         fi
      fi
   done
   # clean the existing blskeys
   rm -f files/blskeys/*.key
   rm -f files/multikey.txt

   for idx in ${indexes[@]}; do
      _do_copy_blskeys $idx
      echo $idx >> files/multikey.txt
   done
   tag=$(cat files/multikey.txt | tr "\n" "-" | sed "s/-$//")
   cp -f files/harmony-mk.service files/service/harmony.service
   _do_launch_one ${indexes[0]} "s${shard}-a2-${tag}"

   copy_mk_pass $IP
   rclone_sync $IP
   do_wait $IP
}

# copy one blskey keyfile files/blskeys directory
function _do_copy_blskeys
{
   index=$1
   key=$(grep "Index:...$index " $HARMONYDB | grep -oE 'BlsPublicKey:..[a-z0-9]+' | cut -f2 -d: | tr -d \" | tr -d " ")
   aws s3 cp s3://harmony-secret-keys/bls/${key}.key files/blskeys/${key}.key
}

# copy bls.pass to .hmy/blskeys
function copy_mk_pass
{
   ips=$@
   for ip in $ips; do
      $SSH hmy@$ip 'cd .hmy/blskeys; for f in *.key; do p=${f%%.key}; cp /home/hmy/bls.pass $p.pass; done'
   done
}

# use rclone to sync harmony db
function rclone_sync
{
   ips=$@
   if $SYNC; then
     folder=mainnet.min
   else
     folder=mainnet
   fi

   for ip in $ips; do
      sleep 5
      $SSH hmy@$ip "nohup /home/hmy/rclone.sh $folder > rclone.log 2> rclone.err < /dev/null &"
   done
}

function do_wait
{
   ips=$@
   declare -A DONE

   for ip in $ips; do
      DONE[$ip]=false
   done

   min=0
   while true; do
      for ip in $ips; do
         rc=$($SSH hmy@$ip 'pgrep -n rclone')
         if [ -n "$rc" ]; then
            echo "rclone is running on $ip. pid: $rc."
         else
            echo "rclone is not running on $ip."
         fi
         hmy=$($SSH hmy@$ip 'pgrep -n harmony')
         if [ -n "$hmy" ]; then
            echo "harmony is running on $ip. pid: $hmy"
            DONE[$ip]=true
         else
            echo "harmony is not running on $ip."
         fi
      done

      alldone=true
      for ip in $ips; do
         if ! ${DONE[$ip]}; then
            alldone=false
            break
         fi
      done

      if $alldone; then
         echo All Done!
         break
      fi
      echo "sleeping 60s, $min minutes passed"
      sleep 60
      (( min++ ))
   done

   for ip in $ips; do
      $SSH hmy@$ip 'tac latest/zerolog*.log | grep -m 1 BINGO'
   done
   date
}

function update_uptime
{
   ips=$@
   for ip in $ips; do
      idx=$($SSH hmy@$ip 'cat index.txt')
      shard=$(( $idx % 4 ))
      echo ./uptimerobot.sh -t n1 -i $idx update m5-$idx $ip $shard
      echo ./uptimerobot.sh -t n1 -i $idx -G update m5-$idx $ip $shard
   done
}

##############################################################################
SYNC=true
REG=random

while getopts "hvS" option; do
   case $option in
      v) VERBOSE=true ;;
      S) SYNC=true ;;
      r) REG="${OPTARG}" ;;
      h|?|*) usage ;;
   esac
done

shift $(($OPTIND-1))

CMD="$1"
shift

if [ -z "$CMD" ]; then
   usage
fi

init_check
get_regions

case $CMD in
   new) new_instance $@ ;;
   rclone) rclone_sync $@ ;;
   wait) do_wait $@ ;;
   uptime) update_uptime $@ ;;
   newmk) do_new_mk $@ ;;
   *) usage ;;
esac
