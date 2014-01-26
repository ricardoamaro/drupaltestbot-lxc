class debugging {
  package { php5-xdebug: }

  # In php5.5 the directory structure changes a bit...
#  file { "/etc/php5/conf.d/xdebug.ini":
#    source => "puppet:///modules/debugging/etc/php5/conf.d/xdebug.ini",
#    replace => true,
#    require => Package['php5-xdebug'],
#    # This will need to notify the correct service, which will change to php5-fpm
#    notify => Service['apache2'],
#  }

  if $drupaltestbot_is_mounted {
    # If the /var/lib/drupaltestbot is likely mounted from the host, we want
    # to do local stuff locally, so move files, checkout, etc. local.
    exec { 'rmdir files':
      command => '/bin/chmod +w -R /var/lib/drupaltestbot/sites/default/files && /bin/rm -rf /var/lib/drupaltestbot/sites/default/files',
      onlyif => '/usr/bin/test -d /var/lib/drupaltestbot/sites/default/files',
      refreshonly => true,
    }
    file { "/var/lib/drupaltestbot/sites/default":
      ensure => directory,
      mode => 0777,
    }
    file { "/var/lib/drupaltestbot/sites/default/files":
      ensure => link,
      target => "/var/tmp/testbot_files",
      require => [File['/var/lib/drupaltestbot/sites/default'], Exec['rmdir files']],
    }

    file { "/var/tmp/testbot_files":
      ensure => directory,
      owner => 'www-data',
      group => 'www-data',
    }
  }
}
