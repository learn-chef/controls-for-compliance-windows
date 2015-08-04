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
  [{:name => 'ICMPv4', :type => 8,}, {:name => 'ICMPv6', :type => 128 }].each { |protocol|
    control "Ensure the firewall blocks public #{protocol[:name]} Echo Request messages" do
      it 'has at least one rule that blocks access' do
        expect(command(<<-EOH
          (Get-NetFirewallPortFilter -Protocol #{protocol[:name]} |
          Where-Object { $_.IcmpType -eq #{protocol[:type]} } |
          Get-NetFirewallRule |
          Where-Object {
            ($_.Profile -eq "Public") -and
            ($_.Direction -eq "Inbound") -and
            ($_.Enabled -eq "True") -and
            ($_.Action -eq "Block") } |
          Measure-Object).Count -gt 0
          EOH
        ).stdout).to match(/True/)
      end
    end
  }
end
