
### Start with basic configuration variables that are common throughout but might change

# Commit of drush that we should be using
$drush_commit = '25f7940e00'

### Stage definitions for ordering
stage { "base-prepare": before => Stage[main] }
stage { "base-prealable": before => Stage[base-prepare] }
stage { "base-final": }
Stage['main'] -> Stage['base-final']

### Modules common to all
include base
include base::apt
include base::apt_prepare
include base::apt::standard
include base::final
include drush
include testing_bot
include git_reference

if !$drupaltestbot_is_mounted {
  include drupaltestbot
} else {
  notify { "Skipping install of drupaltestbot module because /var/lib/drupaltestbot is mounted.": }
}

# If running vagrant/virtualbox. We may want to enable in other contexts as well
if $virtual == 'virtualbox' {
  include debugging
  include vagrant
  $puppet_status = false
  $xdebug_enabled = true
notify { "\$virtual=${virtual} so skipping firewall and including debugging and vagrant modules.": }
}
else {
  $puppet_status = true
  include "firewall"
  $xdebug_enabled = false
}

# Default is mysql build.
node default {
  include testing_bot::mysql
}

# If the name of the server contains -pgsql, use the PostgreSQL profile.
node /pgsql/ {
  include testing_bot::pgsql
}

# If the name of the server contains -sqlite3, use the SQLite profile.
node /sqlite3/ {
  include testing_bot::sqlite3
}

