require 'spec_helper'

describe 'cockpit' do
  let(:facts) { WheezyFacts }

  context 'when running with default parameters' do
    it {
      should compile
      should compile.with_all_deps
      should contain_cockpit
      should_not contain_group('cockpit')
      should_not contain_user('cockpit')
    }
  end

  context 'when running with ensure present' do
    let(:params) { { :ensure => 'present',}}
    it {
      should compile
      should compile.with_all_deps
      should create_class('cockpit')
      should contain_file('/etc/init.d/cockpit').with_content(/sudo -iHu cockpit --  cd\s+\/opt\/cockpit\/checkout bundle install && COCKPIT_CONFIG=mock_config.yaml .\/elexis-cockpit.rb &> \/var\/log\/elexis-cockpit.log /)
      should contain_vcsrepo('/opt/cockpit/checkout')
      should contain_group('cockpit')
      should contain_user('cockpit').only_with( { :ensure => 'present', :name => 'cockpit'} )
    }
  end

  context 'when running with ensure absent' do
    let(:params) { { :ensure => 'absent' } }
    it {
      should compile
      should compile.with_all_deps
      should create_class('cockpit')
      should_not contain_group('cockpit')
      should_not contain_user('cockpit')
    }
  end
end
