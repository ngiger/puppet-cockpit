require 'spec_helper'

describe 'cockpit::service' do
  let(:facts) { WheezyFacts }

  context 'when running with default parameters' do
    it {
     should compile
     should compile.with_all_deps
     should contain_cockpit
    }
  end

  context 'when running with ensure absent' do
    let(:params) { { :ensure => 'absent' } }
    it {
      should compile
      should compile.with_all_deps
      should create_class('cockpit')
      should create_vcsrepo('/opt/cockpit/checkout')
    }
  end

  context 'when running with ensure present and systemd' do
    let(:params) { { :ensure => 'present',}}
    it {
      should compile
      should compile.with_all_deps
      should create_class('cockpit')

      should contain_exec('gen_mockconfig')
      should contain_exec('restart_cockpit_via_systemctl')
      should contain_package('bundler')
      should contain_package('systemd')
      should contain_package('systemd-sysv')
      should contain_user('cockpit')
      should contain_vcsrepo('/opt/cockpit/checkout')
      should contain_file('/etc/elexis_cockpit').with({:ensure => 'absent', :recurse => true})
      should contain_file('/etc/init.d/cockpit').with({:ensure => 'absent'})
      should contain_file('/opt/cockpit/checkout/start.sh').with_content(/cd\s+\/opt\/cockpit\/checkout/)
      should contain_file('/opt/cockpit/checkout/start.sh').with_content(/bundle\s+install\nbundle\s+exec\s+ruby\s+elexis-cockpit.rb/)
      should contain_file('/etc/systemd/system/cockpit.service').with_content(/^\[Service\]
ExecStart\s*=\s*\/opt\/cockpit\/checkout\/start.sh
User\s*=\s*cockpit
Group\s*=\s*cockpit
/ )
    }
  end
end
