class vagrant {
  # This is only necessary for the vagrant environment, which doesn't get this delivered
  # from puppetd. Unfortunately this is also an unmanaged copy of the real one.
  file { "/var/lib/puppet/lib/facter":
    source => "puppet:///modules/vagrant/var/lib/puppet/lib/facter",
    recurse => true,
    purge => false,
  }

}
