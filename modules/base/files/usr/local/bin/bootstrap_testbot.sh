#!/bin/bash -x

NOTIFY_EMAILS=randy@randyfay.com,jthorson@sasktel.net

HOSTNAME=$(curl -fs http://169.254.169.254/latest/meta-data/public-hostname/) \
&& IPADDR=$(curl -fs http://169.254.169.254/latest/meta-data/local-ipv4/)
if ! test -z "$HOSTNAME" && ! test -z "$IPADDR"; then
  echo $HOSTNAME >/etc/hostname
  hostname $HOSTNAME
  echo "127.0.0.1 localhost localhost.localdomain
  $IPADDR  $HOSTNAME" >/etc/hosts
fi

# exim4 will cause postfix install to fail
apt-get -y remove exim4-base exim4-config

# Get puppet installed, but 2.7 as 2.6 is no longer compatible with our puppetmaster
apt-get -y update && apt-get -y install puppet
# Make sure pluginsync is set in the main section of puppet.conf
perl -pi.bak -e 's%\[main\]%[main]\npluginsync=true\n%' /etc/puppet/puppet.conf
puppet agent --test --server testbotmaster.devdrupal.org >/tmp/puppetd.out 2>&1

rv=$?
output=$(cat /tmp/puppetd.out)

# get postfix and mailutils in there in case puppet failed to do so
# apt-get -y install postfix mailutils
apt-get -y install postfix mailutils

echo "
Testbot creation puppet run return value=$rv on $(hostname)
http://$(hostname)

Add it to qa.drupal.org at
rfay: http://qa.drupal.org/user/58/pifr/add
jthorson: http://qa.drupal.org/user/549/pifr/add

puppet run=
$output
" | mail -s "Testbot $(hostname) created" $NOTIFY_EMAILS
