
class testing_bot {
  # Create the mount point.
  file { "/tmpfs":
    ensure => directory,
  }

  # A wild tmpfs mount.
  mount { "/tmpfs":
    device => "tmpfs",
    atboot => true,
    options => "size=2547480000,rw",
    ensure => mounted,
    fstype => "tmpfs",
    require => File["/tmpfs"],
    remounts => false,
  }

  # Backup some important data to disk.
  package { "rsync":
    ensure => present,
  }
  file { "/etc/init.d/disk-backup":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet:///modules/testing_bot/disk-backup",
    require => Package["rsync"],
    notify  => Exec["install-disk-backup"],
  }
  exec { "install-disk-backup":
    path        => "/usr/bin:/bin:/usr/sbin:/sbin",
    command     => "update-rc.d disk-backup defaults 08",
    refreshonly => true,
  }

  # Mysql Configuration, we always install MySQL regardless of the test
  # environment because the test client itself needs that.
  include "mysql::server"

  # Move MySQL's data directory to the tmpfs.
  file { "/etc/mysql/conf.d/tmpfs.cnf":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet:///modules/testing_bot/mysql-tmpfs.cnf",
    notify  => Exec["initial-backup"],
    require => Package["mariadb-server-5.5"],
  }

  # Perform the initial backup of the database once MySQL has been installed.
  exec { "initial-backup":
    path        => "/usr/bin:/bin:/usr/sbin:/sbin",
    command     => "/etc/init.d/mysql stop && cp -a /var/lib/mysql /tmpfs/mysql && touch /tmpfs/.backup-done && /etc/init.d/disk-backup stop && /etc/init.d/mysql start",
    creates     => "/tmpfs/.backup-done",
    require     => [ Package["mariadb-server-5.5"], Mount["/tmpfs"], File["/etc/init.d/disk-backup"], File["/etc/mysql/conf.d/tmpfs.cnf"] ]
  }

  package { ["apache2", "libapache2-mod-php5", "curl" ]:
    ensure => present,
  }
  package { "ntp":
    ensure => present,
  }

  # include pear packages.

  pear { "Console_Table":
    package => "Console_Table",
    creates => "/usr/share/php/Console/Table.php",
  }
  pear { "drush":
    package => "drush/drush",
    creates => "/usr/bin/drush",
    channel => "pear.drush.org",
  }
  pear { "Archive_Tar":
    package => "Archive_Tar",
    creates => "/usr/share/doc/php5-common/PEAR/Archive_Tar",
  }


  service { "apache2":
    require => Package["apache2"],
  }

  # Additional PHP modules.
  package { ["php5", "php5-gd", "php5-cli", "php5-curl", "php5-xsl", "php5-imap", "php5-mcrypt", "php5-sqlite", "php5-intl", 'php5-xmlrpc', 'php-pear']:
    notify => Service["apache2"],
    require => File['/etc/apt/preferences.d/php'],
  }

  # APC gets replace by zen opcode cache in 5.5
  if $php_major_version < "5.5" {
    package { "php5-apc": }
  }

  # Enable the rewrite module.
  exec { "a2enmod-rewrite":
    creates => "/etc/apache2/mods-enabled/rewrite.load",
    command => "/usr/sbin/a2enmod rewrite",
    require => Package["apache2"],
    notify  => Service["apache2"],
  }
  # Enable the ssl module.
  exec { "a2enmod-ssl":
    creates => "/etc/apache2/mods-enabled/ssl.load",
    command => "/usr/sbin/a2enmod ssl",
    require => Package["apache2"],
    notify  => Service["apache2"],
  }


  file { "/etc/php5/apache2/php.ini":
    owner   => root,
    group   => root,
    mode    => 644,
    source  => "puppet:///modules/testing_bot/etc/php5/apache2/php${php_major_version}/php.ini",
    require => Package["libapache2-mod-php5"],
    notify  => Service["apache2"],
  }

  file { "/etc/php5/conf.d":
    owner   => root,
    group   => root,
    mode    => 644,
    source  => "puppet:///modules/testing_bot/etc/php5/conf.d/php${php_major_version}",
    recurse => true,
    purge => false,
    notify  => Service["apache2"],
    require => Package['apache2'],
  }

  file { "/etc/php5/cli/php.ini":
    owner   => root,
    group   => root,
    mode    => 644,
    source  => "puppet:///modules/testing_bot/etc/php5/cli/php${php_major_version}/php-cli.ini",
    require => Package["php5-cli"],
  }
  file { "/var/log/apache2/php-errors.log":
    owner => apache2,
    group => adm,
    mode => 666,
  }


  file { "/etc/apache2/conf.d/other-vhosts-access-log":
    owner => root,
    group => root,
    mode => 644,
    source => "puppet:///modules/testing_bot/other-vhosts-access-log",
    notify => Service["apache2"],
    require => Package['apache2'],
  }

  file { "/etc/logrotate.d/apache2":
    owner => root,
    group => root,
    mode => 644,
    source => "puppet:///modules/testing_bot/apache2.logrotate",
    require => Package['apache2'],
  }

  file { "/etc/dbconfig-common":
    ensure => directory,
  }
  file { "/etc/dbconfig-common/config":
    ensure => present,
    source => "puppet:///modules/testing_bot/etc/dbconfig-common/config",
    require => File["/etc/dbconfig-common"],
  }

  class mysql {
    package { "drupaltestbot-mysql":
      ensure => present,
      require => Exec["initial-backup"] ,
    }
  }

  class pgsql {
    package { "drupaltestbot-pgsql":
      ensure => present,
    }
  }

  class sqlite3 {
    package { "drupaltestbot-sqlite3":
      ensure => present,
    }
  }
}
