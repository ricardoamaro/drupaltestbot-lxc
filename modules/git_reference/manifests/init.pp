class git_reference {

  file { ["/var/cache/git", "/var/cache/git/reference"]:
    ensure => directory,
  }

  exec { "initialize_git_cache":
    command => "/usr/bin/git --git-dir /var/cache/git/reference init --bare",
    creates => "/var/cache/git/reference/config",
    require => File['/var/cache/git/reference'],
    timeout => 0,
  }

  cron { "update_git_cache":
    command => "/usr/bin/git --git-dir /var/cache/git/reference fetch --all",
    user => root,
    hour => 0,
    minute => 1,
  }

  file { "/var/cache/git/reference/config":
    source => "puppet:///modules/git_reference/var/cache/git/reference/config",
    require => Exec[ 'initialize_git_cache'],
  }
}
