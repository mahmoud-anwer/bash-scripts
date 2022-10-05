# bash-scripts
## monitoring-domains-certificates.sh
- Monitoring domains certificates expiration date and send a notification to Slack.
### How to start
- Add your domains to 'domains' file in the below format and be careful there is a space after the colon.
```bash
# collection1
domain: test1.com
domain: test2.com
# collection2
domain: test3.com
domain: test4.com
```
- Change the file script permissions to be executable.
```bash
chmod +x monitoring-domains-certificates.sh
```
- Run the script.
```bash
./monitoring-domains-certificates.sh
```