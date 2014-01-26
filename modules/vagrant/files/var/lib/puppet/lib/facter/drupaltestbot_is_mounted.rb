# Detect if /var/lib/drupaltestbot is mounted, which means DO NOT install drupaltestbot package.
require 'facter'
Facter.add(:drupaltestbot_is_mounted) do
  setcode do
    Facter::Util::Resolution.exec("df | grep /var/lib/drupaltestbot >/dev/null && echo 1")
  end
end
