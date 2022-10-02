# bash-scripts
## monitoring-domains-certificates.sh
- Monitoring domains certificates expiration date and send a notification to Slack.
### How to start
- Add your domains to 'domains' file as one per line and make sure the last line in the file has the '@' character.
- Change the file script permissions to be executable.
```bash
chmod +x monitoring-domains-certificates.sh
```
- Run the script.
```bash
./monitoring-domains-certificates.sh
```