#!/bin/bash

# to exit as soon as any line in the bash script fails.
set -e

notify() {
  webhook=""
  slack_channel="#monitor-certificates"
  
  color="$1"
  certificate="$2"
  days="$3"
  expiration_date="$4"
  
  slack_payload="payload={\"channel\":\"${slack_channel}\",\"attachments\":[{\"color\":\"${color}\",\"fields\":[{\"title\":\"Certificate:\",\"value\":\"${certificate}\",\"short\":false},{\"title\":\"Expired within day(s):\",\"value\":\"${days}\",\"short\":true},{\"title\":\"Expiration date:\",\"value\":\"$expiration_date\",\"short\":true}]}]}"
  
  curl -X POST --data-urlencode "$slack_payload" $webhook
}

# Getting certbot certificates
certificates_list=($(certbot certificates | grep 'Certificate Path' | awk '{print $3}'))

for item in ${certificates_list[@]};
do
    for days in 1 5 7; # start of inner loop
    do
        expiration_date=$(date -d "$(openssl x509 -text -in "$item" | grep 'Not After' | awk '{print $4,$5,$7}')" '+%s')
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
    done # End of inner loop
done