#!/bin/bash -x

# You can do anything you want as a cleanup or fixup here
# Any time this file changes it will be rerun on all testbots.

cd /var/lib/drupaltestbot/sites/all/modules/project_issue_file_review && git pull

drush -r /var/lib/drupaltestbot vset pifr_client_server https://qa.drupal.org/
drush -r /var/lib/drupaltestbot vset pifr_client_timeout 180

touch /etc/drupaltestbot/.db_loaded

date >>/tmp/testbot_cleanup_ran.txt

# Force firewall service restart, as it doesn't seem to have run on normal update
if [ -f /etc/init.d/firewall ] ; then
  /etc/init.d/firewall restart
fi
