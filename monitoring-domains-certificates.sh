#!/bin/bash

# set -x
# -e: to exit as soon as any line in the bash script fails.
# -x: to enable debugging mode.

notify() {
  webhook=""
  slack_channel="#monitor-certificates"
  
  color="$1"
  domain="$2"
  days="$3"
  expiration_date="$4"
  
  slack_payload="payload={\"channel\":\"${slack_channel}\",\"attachments\":[{\"color\":\"${color}\",\"fields\":[{\"title\":\"Domain:\",\"value\":\"${domain}\",\"short\":false},{\"title\":\"Expired within day(s):\",\"value\":\"${days}\",\"short\":true},{\"title\":\"Expiration date:\",\"value\":\"$expiration_date\",\"short\":true}]}]}"
  
  curl -X POST --data-urlencode "$slack_payload" $webhook
}

# Read domains from file into 'domains_list' array
read -d '@' -a domains_list < domains

for item in ${domains_list[@]};
do
    for days in 66; # start of inner loop
    do
        not_after_date=$(: | openssl s_client -connect $item:443 -servername $item 2>/dev/null \
                              | openssl x509 -text \
                              | grep 'Not After');
        ######################################################################################################################
        if [ $? -eq 1 ] # Check if getting the certificate goes wrong
        then
            color="#ff0000" # Red color
            days="UNKNOWN"
            expiration_date="UNKNOWN"
            # Call the 'notify' function with its parameters
            notify "$color" "$item" "$days" "$expiration_date"
        else
            expiration_date=$(date -d "$(echo $not_after_date | awk '{print $4,$5,$7}')" '+%s');
            after_some_days=$(($(date +%s) + (86400*$days)));

            # Send slack notification
            if [ $after_some_days -gt $expiration_date ]
            then
                # If the certificate will expire within 1 day, the color of notification will be red else it will be green
                if [ $days -eq 1 ]
                then
                    color="#ff0000" # Red color
                else
                    color="#2eb886" # Green color
                fi
                # Call the 'notify' function with its parameters
                notify "$color" "$item" "$days" "$(date -d @$expiration_date '+%d-%m-%Y')"
                break
            fi
        fi
        ######################################################################################################################
    done # End of inner loop
done