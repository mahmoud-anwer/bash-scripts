#!/bin/bash

# Slack webhook
webhook_url=your_slack_webhook

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
            curl -X POST -H 'Content-type: application/json' \
                 --data '{"text":"Warning: The certificate ('$item') will expire within ('$days') days on host ('$HOSTNAME') on '$(date -d @$expiration_date '+%d-%m-%Y')' "}' \
                 $webhook_url
            break
        fi
    done # End of inner loop
done