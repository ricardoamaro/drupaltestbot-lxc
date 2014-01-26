require 'facter'
Facter.add(:php_major_version) do
  setcode do
    Facter::Util::Resolution.exec("cat /etc/php_major_version 2>/dev/null || echo '5.3'")
  end
end
