
# A set of simple rules around iptables.

class firewall {
  File {
    owner => root,
    group => root,
    mode => 644,
  }
  file { "/etc/init.d/firewall":
    source  => "puppet:///modules/firewall/init.d/firewall",
    mode => 755,
    notify => Service["firewall"]
  }
  file { "/etc/default/firewall":
    source  => "puppet:///modules/firewall/default/firewall",
  }
  file { "/etc/firewall.d":
    ensure => "directory",
  }
  file { "/etc/firewall.d/00clear":
    source  => "puppet:///modules/firewall/firewall.d/00clear",
    mode => 755,
  }
  file { "/etc/firewall.d/05policies":
    source  => "puppet:///modules/firewall/firewall.d/05policies",
    mode => 755,
  }

  service { "firewall":
    enable => true,
    require => File["/etc/init.d/firewall"],
    hasrestart => true,
  }
}

define firewall::rule($ensure = "present", $content) {
  file { "/etc/firewall.d/50$name":
    owner => root,
    group => root,
    mode => 755,
    content => template("firewall/rule.rb"),
    ensure => $ensure,
    notify => Service["firewall"],
  }
}

define firewall::rule::allow_servers($ensure = "present", $protocol, $port, $servers) {
  file { "/etc/firewall.d/50$name":
    owner => root,
    group => root,
    mode => 755,
    content => template("firewall/allow_servers.rb"),
    ensure => $ensure,
    require => Class['firewall'],
    notify => Service["firewall"],
  }
}


firewall::rule::allow_servers { "ssh":
  protocol => tcp,
  port => ssh,
  servers => [ "0.0.0.0/0" ],
}
# Firewall configuration.
firewall::rule::allow_servers { "http":
  protocol => tcp,
  port => 80,
  # testbotmaster.devdrupal.org, OSUOSL Jumphost
  servers => [ "140.211.10.25/32", "10.20.0.0/16" ],
}
firewall::rule::allow_servers { "https":
  protocol => tcp,
  port => 443,
  # testbotmaster.devdrupal.org, OSUOSL Jumphost
  servers => [ "140.211.10.25/32", "10.20.0.0/16" ],
}
