
class mysql {
  package { "maatkit":
    ensure => present,
  }

  class server {
    package { "mariadb-server-5.5":
      ensure => present,
    }

    service { "mysql":
      enable => true,
      require => Package["mariadb-server-5.5"],
      hasrestart => true,
    }

    file { "/etc/mysql/my.cnf":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet:///modules/mysql/my.cnf",
      require => Package["mariadb-server-5.5"],
      notify  => Service["mysql"],
    }

    file { "/etc/mysql/conf.d/tuning.cnf":
      owner   => root,
      group   => root,
      mode    => 755,
      source  => "puppet:///modules/mysql/tuning.cnf",
      require => Package["mariadb-server-5.5"],
      notify  => Service["mysql"],
    }
  }
}
