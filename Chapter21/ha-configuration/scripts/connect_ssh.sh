#!/usr/local/bin/bash

# Script to connect to one or all amazon ec2 hosts in this play
# This only works on Mac currently!

# Source the code that generates seperate terminal windows
. scripts/new_window.sh

# Define the hosts
declare -A cluster_hosts

cluster_hosts=( ["bastion1"]=`/usr/local/bin/terraform.py| jq '.security.hosts[0]'` \
["bastion2"]=`/usr/local/bin/terraform.py| jq '.security.hosts[1]'` \
["frontend0"]=`/usr/local/bin/terraform.py| jq '.frontend.hosts[0]'` \
["frontend1"]=`/usr/local/bin/terraform.py| jq '.frontend.hosts[1]'` \
["middleware0"]=`/usr/local/bin/terraform.py| jq '.middleware.hosts[0]'` \
["middleware_asap"]=`/usr/local/bin/terraform.py| jq '.middleware_asap.hosts[0]'` \
["middleware_realtime"]=`/usr/local/bin/terraform.py| jq '.middleware_realtime.hosts[0]'` \
["middleware_pipelines"]=`/usr/local/bin/terraform.py| jq '.middleware_pipelines.hosts[0]'` \
["red0"]=`/usr/local/bin/terraform.py| jq '.redis.hosts[0]'` \
["red1"]=`/usr/local/bin/terraform.py| jq '.redis.hosts[1]'` \
["db0"]=`/usr/local/bin/terraform.py| jq '.db.hosts[0]'` \
["db1"]=`/usr/local/bin/terraform.py| jq '.db.hosts[1]'` \
["db2"]=`/usr/local/bin/terraform.py| jq '.db.hosts[2]'` \
["cs0"]=`/usr/local/bin/terraform.py| jq '.consul.hosts[0]'` \
["cs1"]=`/usr/local/bin/terraform.py| jq '.consul.hosts[1]'` \
["cs2"]=`/usr/local/bin/terraform.py| jq '.consul.hosts[2]'` \
["pg0"]=`/usr/local/bin/terraform.py| jq '.pgbouncer.hosts[0]'` \
["gitaly0"]=`/usr/local/bin/terraform.py| jq '.gitaly.hosts[0]'` \
["grafana0"]=`/usr/local/bin/terraform.py| jq '."monitoring-dashboard".hosts[0]'`) 


function connect_to_host  {

    host_code=$1
    ssh_host=$2

    echo "Connecting to $host_code - $ssh_host  "


        #If host is a bastion host we use a different connection method 
        if [[ $host_code =~ ^bastion[0-9]+$ ]]
        then

            echo "ssh -o StrictHostKeyChecking=no -i /tmp/mykey.pem ubuntu@$ssh_host -t \"echo \"PS1=$host_code\"$\"\">>~/.bashrc;bash\" "
            new_window "ssh -o StrictHostKeyChecking=no -i /tmp/mykey.pem ubuntu@$ssh_host -t \"echo \"PS1=$host_code\"$\"\">>~/.bashrc;bash\" "

        else

            new_window "ssh  -i /tmp/mykey.pem ubuntu@$ssh_host -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /tmp/mykey.pem   -W %h:%p -q ubuntu@${cluster_hosts['bastion1']}\" -t \"echo \"PS1=$\"$host_code:$ssh_host$\"\">>~/.bashrc;bash\" 2>/dev/null "

        fi


}

# Main 

# Usage if no args
if [[ $# -eq 0 ]] ; then
    echo 'Usage: connect_ssh all OR connect_ssh [hostcode] OR connect_ssh show_host_codes'
    exit 0
fi

# Iterate input args
case "$1" in

    "all") for host in "${!cluster_hosts[@]}"; do connect_to_host $host ${cluster_hosts[$host]}; done;;
    "show_host_codes") for host in "${!cluster_hosts[@]}"; do echo "hostcode: $host -- hostname: ${cluster_hosts[$host]}"; done;;
    *) connect_to_host $1 ${cluster_hosts[$1]};

esac
