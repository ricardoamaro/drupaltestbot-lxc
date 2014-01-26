#
# Explicit stage for pre-initialization tasks.
#
# Some tasks need to be executed before everything else (especially APT
# repository configuration). We define an explicit stage here to avoid
# dependency issues.
#

# Parent class for all systems.
# Configure APT repositories and ensure freshness of packages.
class base {

  file { "/etc/puppet/puppet.conf":
    source => "puppet:///modules/base/etc/puppet/puppet.conf",
    notify => Service["puppet"],
  }

  file { "/etc/default/puppet":
    source => "puppet:///modules/base/etc/default/puppet",
    owner => 'root',
    group => 'root',
    notify => Service['puppet'],
  }

  package { "puppet":
    ensure => latest,
  }
  service { "puppet":
    enable => $puppet_status,
    ensure => $puppet_status,
    require => Package['puppet'],
  }

  class { "base::apt_prepare": stage => "base-prealable" }
  class { "base::apt::standard": stage => "base-prepare" }
  class { "base::final": stage => "base-final" }

  # Locales configuration.
  file { "/etc/locale.gen":
    source => "puppet:///modules/base/etc/locale.gen",
    require => Package["locales"],
    notify => Exec["locale-gen"],
    owner => 'root',
    group => 'root',
  }
  file { "/etc/default/locale":
    source => "puppet:///modules/base/etc/default/locale",
    require => Package["locales"],
    owner => 'root',
    group => 'root',
  }
  exec { "locale-gen":
    path        => "/usr/bin:/bin:/usr/sbin:/sbin",
    command     => "locale-gen",
    refreshonly => true,
    logoutput => true,
  }
  package { "locales": }

  # Generally needed packages
  package { ["telnet", "lynx", "strace", "xtail", "htop", "postfix", "sudo", "openssh-server", ]: }

  package { ["git", "git-core"]:
    ensure => present,
    require => File['/etc/apt/preferences.d/git'],
  }

  # Login configuration.
  file { "/etc/login.defs":
    owner   => root,
    group   => root,
    mode    => 644,
    source  => "puppet:///modules/base/login.defs",
  }

  file { "/etc/sudoers":
    owner   => root,
    group   => root,
    mode    => 440,
    source  => "puppet:///modules/base/etc/sudoers",
    require => Package["sudo"],
  }

  # SSH configuration.
  service { "ssh":
    pattern => "/usr/sbin/sshd",
    hasrestart => true,
    hasstatus => true,
    require => Package["openssh-server"]
  }
  file { "/etc/ssh/sshd_config":
    source => "puppet:///modules/base/etc/ssh/sshd_config",
    require => Package["openssh-server"],
    notify => Service["ssh"],
    owner => 'root',
    group => 'root',
  }

  # Standard default database dump
  file { "/tmp/drupaltestbot.sql.gz":
    source => "puppet:///modules/base/drupaltestbot.sql.gz",
  }

  # Maintainers keys
  file { "/root/.ssh":
    ensure   => directory,
    owner    => root,
    group    => root,
    mode     => 0700,
  }

  # Although authorized_keys2 is deprecated, it still works everywhere I know
  # As a result we can use *it* as the puppet-managed version of authorized_keys
  # and /root/authorized_keys as the box-managed version.
  file { "/root/.ssh/authorized_keys2":
    source => "puppet:///modules/base/root/.ssh/authorized_keys2",
    owner => root,
    group => root,
    mode => 0600,
  }

  file { "/usr/local/bin":
    ensure => present,
    owner => root,
    group => root,
    mode => 0755,
    recurse => true,
    purge => false,
    source => "puppet:///modules/base/usr/local/bin",
  }
}

class base::apt_prepare {
  exec { "apt-update":
    command => "/usr/bin/apt-get update && touch /var/tmp/.apt-update_done",
    timeout => 0,
    creates => "/var/tmp/.apt-update_done",
  }

  package { "debian-archive-keyring":
    ensure => latest,
    require => Exec["apt-update"],
  }

  # Change content of base/files/etc/upgrade_initiator in any way you want to
  # when an upgrade should be performed.
  # From http://www.memonic.com/user/pneff/folder/55756627-f51c-43f0-adfd-777635574108/id/1Z9999x
  file { "/etc/upgrade_initiator":
    source => "puppet:///modules/base/etc/upgrade_initiator",
  }

  exec { "/usr/bin/apt-get -y upgrade":
    refreshonly => true,
    subscribe => File["/etc/upgrade_initiator"],
    environment => "DEBIAN_FRONTEND=noninteractive",
    require => Exec["apt-update"],
    timeout => 0,
  }

  package { 'exim4-base':
    ensure => absent,
  }

  # Make sure we have bash completion
  file { "/etc/bash.bashrc":
    source => "puppet:///modules/base/etc/bash.bashrc",
  }

}

#
# Standard APT configuration for the test bots.
#
class base::apt::standard {
  include base::apt

  file { "/etc/apt/sources.list":
    source => "puppet:///modules/base/etc/apt/sources.list",
  }
  base::apt::repository { "maria":
    repository_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/maria.sources.list",
    key_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/maria.public.key",
    key_id => "1BB943DB",
  }

  base::apt::repository { "puppetlabs":
    repository_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/puppetlabs.sources.list",
    key_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/puppetlabs.public.key",
    key_id => "4BD6EC30",
  }

  base::apt::repository { "testbotmaster":
    repository_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/testbot.sources.list",
    key_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/testbot.public.key",
    key_id => "A19A51A2",
  }

  base::apt::repository { "dotdeb":
    repository_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/dotdeb.sources.list",
    key_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/dotdeb.public.key",
    key_id => "89DF5277",
  }

  base::apt::repository { "squeeze":
    repository_source => "puppet:///modules/base/etc/apt/sources.list.d/php${php_major_version}/squeeze.sources.list",
  }
}
class base::final {
  # Any change to testbot_cleanup.sh will result in it being run on the testbots.
  exec { "/usr/local/bin/testbot_cleanup.sh":
    refreshonly => true,
    subscribe => File["/usr/local/bin/testbot_cleanup.sh"],
    environment => "DEBIAN_FRONTEND=noninteractive",
    require => File["/usr/local/bin/testbot_cleanup.sh"],
  }
  file { "/usr/local/bin/testbot_cleanup.sh":
    source => "puppet:///modules/base/usr/local/bin/testbot_cleanup.sh",
    mode => 0777,
    require => File['/usr/local/bin'],
  }
}
