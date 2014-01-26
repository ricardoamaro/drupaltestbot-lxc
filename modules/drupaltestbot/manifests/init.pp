class drupaltestbot {


  # Overwrite the dbconfig for drupaltestbot packages so we don't try to
  # reconfigure them on upgrade. Theoretically this would be handled better
  # with a preseeed file or just building the package right,
  # but I don't know how to do that yet.
  file { "/etc/dbconfig-common/drupaltestbot.conf":
    ensure => present,
    source => "puppet:///modules/drupaltestbot/etc/dbconfig-common/drupaltestbot.conf",
    require => Package['drupaltestbot'],
  }
  file { "/etc/dbconfig-common/drupaltestbot-mysql.conf":
    ensure => present,
    source => "puppet:///modules/drupaltestbot/etc/dbconfig-common/drupaltestbot-mysql.conf",
    require => Package['drupaltestbot-mysql'],
  }

  exec { 'pifr git pull':
    command => 'cd /var/lib/drupaltestbot/sites/all/modules/project_issue_file_review && git pull',
    path => "/usr/bin:/bin:/usr/sbin:/sbin",
    require => Package['git'],
    refreshonly => true,
  }
  package { "drupaltestbot":
    ensure => "present",
    require => Exec["initial-backup"],
    notify => Exec['pifr git pull'],
  }

  #### Various cleanup stuff to finish a testbot that may not be useful or correct

  # Load the database from the starter file *if* we don't already have tables
  # populated in it.
  exec { "dbload":
    command => "test $(drush -r /var/lib/drupaltestbot sqlq 'show tables;' | wc -l) -gt 0 || (touch /etc/drupaltestbot/.db_loaded &&  gzip -dc /tmp/drupaltestbot.sql.gz | mysql drupaltestbot)",
    require => [Package['drupaltestbot'], File['/tmp/drupaltestbot.sql.gz'], Pear['drush']],
    creates => "/etc/drupaltestbot/.db_loaded",
    path        => "/usr/bin:/bin:/usr/sbin:/sbin",
  }

  exec { "drush-set-sitename":
    command => "drush -r /var/lib/drupaltestbot vset site_name 'testbot: ${hostname} (${ipaddress})' && touch /etc/drupaltestbot/.site_name_set",
    require => Exec['dbload'],
    creates => "/etc/drupaltestbot/.site_name_set",
    path => "/usr/bin:/bin:/usr/sbin:/sbin",
  }

  exec { "drush-set-https-qa":
    command => "drush -r /var/lib/drupaltestbot vset pifr_client_server https://qa.drupal.org/ && touch /etc/drupaltestbot/.qa_url_set",
    require => Exec['dbload'],
    creates => "/etc/drupaltestbot/.qa_url_set",
    path => "/usr/bin:/bin:/usr/sbin:/sbin",
  }

}

