# -*- mode: ruby -*-
# vi: set ft=ruby :

# Load a Vagrantfile.local if it exists, see Vagrantfile.local.example.
dirname = File.dirname(__FILE__)
localfile = dirname + "/Vagrantfile.local"
if File.exist?(localfile)
  load localfile
end

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "DebianWheezy64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://testbotmaster.devdrupal.org/DebianWheezy64.box"

  if !defined? $ipaddress
    $ipaddress = "172.16.2.100"
  end
  config.vm.network :private_network, ip: $ipaddress

  config.vm.hostname = "vagrantbot.dev"

  config.vm.provider :virtualbox do |vb|
    # You can set $virtualbox_memory in Vagrantfile.local
    # if you want more or less.
    # for example:
    # $virtualbox_memory = "2048"
    if !defined? $virtualbox_memory
      $virtualbox_memory = "1024"
    end
    vb.customize ["modifyvm", :id, "--memory", $virtualbox_memory]

    if !defined? $virtualbox_cpus
      $virtualbox_cpus = 2
    end
    vb.customize ["modifyvm", :id, "--cpus", $virtualbox_cpus]
  end

  # Enable ssh agent forwarding
  # config.ssh.forward_agent = true

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.module_path = "modules"
    puppet.manifest_file = "site.pp"
  end

  # config.vm.customize ["modifyvm", :id, "--memory", "1024"]

  if defined? $vagrant_apt_cache
    config.vm.synced_folder($vagrant_apt_cache, "/var/cache/apt/archives", :create => true)
  end

  # If you want to mount /var/lib/drupaltestbot from the host machine on the guest, set the
  # $host_docroot in your Vagrantfile.local like one of these:
  # $host_docroot = "~/workspace/gitdev"
  # $host_docroot = "C:/Users/rfay/workspace/gitdev"
  # $host_docroot = nil

  guest_docroot = "/var/lib/drupaltestbot"
  # If a $host_docroot is defined, mount it with NFS (which must be enabled on host)
  if (defined? $host_docroot)
    config.vm.synced_folder $host_docroot, guest_docroot, :nfs => true
  end
end
