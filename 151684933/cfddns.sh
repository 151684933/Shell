#!/bin/bash

# CHANGE THESE
auth_email="q151684933@outlook.com"
auth_key="0282a34534739868b1541ae46cf71a04f065d" 
zone_name="maxseed.top"
record_name1="ddns.maxseed.top"
record_name2="pve.maxseed.top"
record_name3="home.maxseed.top"
zone_identifier="c3ee7696f7387af3c5efefc2a2136db6"
record_identifier1="2ecb369b3ba3603c9651b559f750a1a3"
record_identifier2="2355bf3a28ba76d755a046d57d0bc21f"
record_identifier3="da9fc936230c9ccc412ce7ec4eeeb045"

# MAYBE CHANGE THESE
ip=$(curl -s http://ipv4.icanhazip.com)
ip_file="ip.txt"


# SCRIPT START
update(){
curl -k -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier1" \
     -H "X-Auth-Email: $auth_email" \
     -H "X-Auth-Key: $auth_key" \
     -H "Content-Type: application/json" \
     --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name1\",\"content\":\"$ip\"}";
curl -k -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier2" \
     -H "X-Auth-Email: $auth_email" \
     -H "X-Auth-Key: $auth_key" \
     -H "Content-Type: application/json" \
     --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name2\",\"content\":\"$ip\"}";
curl -k -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier3" \
     -H "X-Auth-Email: $auth_email" \
     -H "X-Auth-Key: $auth_key" \
     -H "Content-Type: application/json" \
     --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name3\",\"content\":\"$ip\"}"
}

if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ $ip == $old_ip ]; then
        echo "IP has not changed."
        exit 0
    else
        echo "IP changed to: $ip"
        echo "$ip" > $ip_file
        update
    fi
else
    echo "$ip" > $ip_file
    update
fi