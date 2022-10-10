#!/bin/bash

# set -x
# -e: to exit as soon as any line in the bash script fails.
# -x: to enable debugging mode.

: '
    Function name: notify
    Parameters: color_of_the_message, domain_name, expired_within_days, expiration_date
'
notify() {
  # Generated webhook used to send notifications
  webhook=""

  # Slack channel name
  slack_channel="#monitor-certificates"
  
  # The parameters of the function
  color="$1"
  domain="$2"
  days="$3"
  expiration_date="$4"
  
  # Slack payload or message that will be sent to the slack channel
  slack_payload="payload={\"channel\":\"${slack_channel}\",\"attachments\":[{\"color\":\"${color}\",\"fields\":[{\"title\":\"Domain:\",\"value\":\"${domain}\",\"short\":false},{\"title\":\"Expired within day(s):\",\"value\":\"${days}\",\"short\":true},{\"title\":\"Expiration date:\",\"value\":\"$expiration_date\",\"short\":true}]}]}"
  
  # Sends the specified data in a POST request to the webhook server with URL encoding
  curl -X POST --data-urlencode "$slack_payload" $webhook
}

: '
    Purpose: Read domains from file into "domains_list" array
        
    cat domains: to list the "domains" file content
    output: 
            ex:
            # section1
            domain: test1.com
            domain: test2.com
            # section2
            domain: test3.com
            domain: test4.com

    grep 'domain': to get only the lines with the word "domain"
    output: domain: test1.com
            domain: test2.com
            domain: test3.com
            domain: test4.com

    awk '{print $2}': to get the domain name
    output: test1.com
            test2.com
            test3.com
            test4.com
    note that awk will use the default space delimiter in this case to get "domain:" in $1 and domain name (ex: test1.com) in $2
'
domains_list=($(cat domains | grep 'domain' | awk '{print $2}'))

# for loop to iterate the 'domiains_list' array
for item in ${domains_list[@]}; # Start of outter loop
do
    # for each item 'domain' in the array I will check if the certificate of the domain will expire within 30 days
    for days in {1..30}; # Start of inner loop
    do
        : '
            Purpose: connect to the domain and get the certificate then extracte the "Not After" date
            openssl s_client -connect $item:443 -servername $item 2>/dev/null: to connect to the domain and get the certificate and forward any errors to /dev/null
            openssl x509 -text: to convert the certificate to text format
            grep 'Not After': to get the "Not After" date
            output: (ex: Not After : Nov 27 22:34:45 2022 GMT)
        '
        not_after_date=$(: | openssl s_client -connect $item:443 -servername $item 2>/dev/null \
                              | openssl x509 -text \
                              | grep 'Not After');
        ######################################################################################################################
        # Check if the above command has failed and getting the certificate goes wrong 
        if [ $? -eq 1 ]
        then
            color="#ff0000" # Red color
            days="UNKNOWN"
            expiration_date="UNKNOWN"
            # Call the 'notify' function with its parameters to send Slack notification
            notify "$color" "$item" "$days" "$expiration_date"
        else
            : '
                Purpose: get the expiration date in seconds
                date -d "date_as_a_string" '+%s': to convert sting date to seconds since 1970-01-01 00:00:00 UTC (Linux official birthday) - epoch time
                echo $not_after_date: (ex: Not After : Nov 27 22:34:45 2022 GMT)
                awk '{print $4,$5,$7}':
                    $4 = Nov
                    $5 = 27
                    $7 = 2022
                output: Nov 27 2022
                note that awk will use the default space delimiter in this case
            '
            expiration_date=$(date -d "$(echo $not_after_date | awk '{print $4,$5,$7}')" '+%s');

            : '
                Purpose: get the date we want to check the certificate validity on it
                date +%s: to get the today date in seconds
                86400*$days: multiply the "days" variable by (24*60*60) to convert it in seconds
            '
            after_some_days=$(($(date +%s) + (86400*$days)));

            # Check if the variable "after_some_days" is greater than the variable "expiration_date" to send Slack notification
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
                # To exit the loop if the condition is met
                break
            fi
        fi
        ######################################################################################################################
    done # End of inner loop
done # End of outter loop