
class base::apt {
  file { "/etc/apt/apt.conf.d/01recommend":
    content => 'APT::Install-Recommends "0"; APT::Install-Suggests "0";'
  }
  file { "/etc/apt/sources.list.d":
    ensure   => directory,
    owner    => root,
    group    => root,
    mode     => 0755,
  }

  exec {"/usr/bin/apt-get update":
    refreshonly => true,
  }

  # Pin php and other packages as required
  file { "/etc/apt/preferences.d/php":
    ensure => present,
    source => "puppet:///modules/base/etc/apt/preferences.d/php/php${php_major_version}",
    notify => Exec["/usr/bin/apt-get update"],
  }
  # temporarily pin git. This can be removed when https://drupal.org/node/2142819 goes in
  file { "/etc/apt/preferences.d/git":
    ensure => present,
    source => "puppet:///modules/base/etc/apt/preferences.d/git",
    notify => Exec["/usr/bin/apt-get update"],
  }

  define repository($repository_source, $key_source = '', $key_id = '', $ensure = 'present') {
    case $ensure {
      present: {
        file { "/etc/apt/sources.list.d/${name}.list":
          source => $repository_source,
          ensure => $ensure,
          notify => Exec["apt-update-$name"],
        }
        if ($key_source) {
          file { "/etc/apt/key-$name":
            source => $key_source,
            ensure => $ensure,
            notify => Exec["import-key-$name"],
          }
          exec { "import-key-$name":
            path        => "/usr/bin:/bin",
            command     => "cat /etc/apt/key-$name | apt-key add -",
            refreshonly => true,
            notify => Exec["apt-update-$name"],
          }
        }
        exec { "apt-update-$name":
          command => "/usr/bin/apt-get update",
          refreshonly => true,
          require => [ File["/etc/apt/apt.conf.d/01recommend"], File["/etc/apt/sources.list.d/${name}.list"] ],
        }
      }
      absent: {
        file { "/etc/apt/sources.list.d/$name":
          ensure => absent,
          notify => Exec["apt-update-$name"],
        }
        if ($key_source) {
          file { "/etc/apt/key-$name":
            ensure => absent,
            notify => Exec["remove-key-$name"],
          }
          exec { "remove-key-$name":
            path => "/usr/bin:/bin",
            command => "apt-key del $key_id",
            refreshonly => true,
            notify => Exec["apt-update-$name"],
          }
        }
        exec { "apt-update-$name":
          command => "/usr/bin/apt-get update",
          refreshonly => true,
          require => [ File["/etc/apt/apt.conf.d/01recommend"], File["/etc/apt/sources.list"], File["/etc/apt/sources.list.d"] ],
        }
      }
    }
  }
}
