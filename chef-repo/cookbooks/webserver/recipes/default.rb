#
# Cookbook Name:: webserver
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
# Block ICMPv4 and ICMPv6 Echo Request messages in the public profile.
%w(ICMPv4 ICMPv6).each { |protocol|
  powershell_script "Block #{protocol} Echo Request messages" do
    code <<-EOH
      $args = @{
        DisplayName = "File and Printer Sharing (Echo Request - #{protocol}-In)"
        Group = "File and Printer Sharing"
        Profile = "Public"
        Protocol = "#{protocol}"
        Enabled = "True"
        Action = "Block"
      }
      New-NetFirewallRule @args
    EOH
    guard_interpreter :powershell_script
    not_if <<-EOH
      (Get-NetFirewallPortFilter -Protocol #{protocol} |
        Get-NetFirewallRule |
        Where-Object {
          ($_.Profile -eq "Public") -and
          ($_.Enabled -eq "True") -and
          ($_.Action -eq "Block")
        }
      ).Count -gt 0
    EOH
  end
}

# Install IIS.
powershell_script 'Install IIS' do
  code 'Add-WindowsFeature Web-Server'
  guard_interpreter :powershell_script
  not_if '(Get-WindowsFeature -Name Web-Server).Installed'
end

# Enable and start W3SVC.
service 'w3svc' do
  action [:enable, :start]
end

# Remove the default IIS start page.
file 'c:/inetpub/wwwroot/iisstart.htm' do
  action :delete
end

# Create the pages directory under the  Web application root directory.
directory 'c:/inetpub/wwwroot/pages'

# Add files to the site.
%w(Default.htm pages/Page1.htm pages/Page2.htm).each do |web_file|
  file File.join('c:/inetpub/wwwroot', web_file) do
    content "<html>This is #{web_file}.</html>"
    owner 'IIS_IUSRS'
  end
end
