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
  control 'Ensure the firewall blocks public ICMPv4 Echo Request messages' do
    it 'has at least one rule that blocks access' do
      expect(command(<<-EOH
        (Get-NetFirewallPortFilter -Protocol ICMPv4 |
        Where-Object { $_.IcmpType -eq 8 } |
        Get-NetFirewallRule |
        Where-Object {
          ($_.Profile -eq "Public") -and
          ($_.Direction -eq "Inbound") -and
          ($_.Enabled -eq "True") -and
          ($_.Group -eq "File and Printer Sharing") -and
          ($_.Action -eq "Block") } |
        Measure-Object).Count -gt 0
        EOH
      ).stdout).to match(/True/)
    end
  end
end
