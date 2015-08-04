#
# Cookbook Name:: audit
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
control_group 'Validate web services' do
  control 'Ensure no web files are owned by the Administrators group' do
    Dir.glob('c:/inetpub/wwwroot/**/*.htm') {|web_file|
      it "#{web_file} must not be owned by Administrators" do
        expect(command("(Get-ChildItem #{web_file} | Get-Acl).Owner").stdout).to_not match(/Administrators$/)
      end
    }
  end
end

control_group 'Validate network configuration and firewalls' do
  %w(ICMPv4 ICMPv6).each { |protocol|
    control "Ensure the firewall blocks public #{protocol} Echo Request messages" do
      it 'has at least one rule that blocks access' do
        expect(command(<<-EOH
          (Get-NetFirewallPortFilter -Protocol #{protocol} |
            Get-NetFirewallRule |
            Where-Object {
              ($_.Profile -eq "Public") -and
              ($_.Enabled -eq "True") -and
              ($_.Action -eq "Block")
            }
          ).Count -gt 0
          EOH
        ).stdout).to match(/True/)
      end
    end
  }
end
