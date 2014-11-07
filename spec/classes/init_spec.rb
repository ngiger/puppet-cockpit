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
      should contain_vcsrepo('/opt/cockpit/checkout')
      should_not contain_group('cockpit')
      should contain_user('cockpit').only_with( { :ensure => 'present', :shell => '/bin/bash', :name => 'cockpit', :managehome => true} )
    }
  end

  context 'when running with ensure absent' do
    let(:params) { { :ensure => 'absent' } }
    it {
      should compile
      should compile.with_all_deps
      should create_class('cockpit')
      should contain_user('cockpit').only_with( { :ensure => 'absent', :name => 'cockpit'} )
      should_not contain_group('cockpit')
    }
  end
end
