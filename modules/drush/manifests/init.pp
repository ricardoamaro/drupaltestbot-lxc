class drush {
  exec { "drush clone":
    command => 'git clone https://github.com/drush-ops/drush.git',
    require => Package['git'],
    cwd => '/opt',
    creates => '/opt/drush/.git',
    path => '/usr/bin',
  }

  exec { "drush checkout":
    command => "git fetch --all && git checkout ${drush_commit}",
    cwd => '/opt/drush',
    require => Exec['drush clone'],
    refreshonly => true,
    path => '/usr/bin',
  }

  file { "/usr/bin/drush":
    ensure => link,
    target => '/opt/drush/drush',
    require => Exec['drush checkout'],
  }

  # Make sure that any old drush versions are gone from /usr/local
  file { ["/usr/local/bin/drush", "/usr/local/lib/drush"]:
    ensure => absent,
    force => true,
  }
}
