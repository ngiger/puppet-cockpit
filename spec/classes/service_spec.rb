require 'spec_helper'

describe 'cockpit::service' do
  let(:facts) { WheezyFacts }
if false
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
    }
    it {
      should_not create_vcsrepo('/opt/cockpit/checkout')
    }
  end
end
  context 'when running with ensure present' do
    let(:params) { { :ensure => 'present',}}
    it {
      should compile
      should compile.with_all_deps
      should create_class('cockpit')
    }
  end

end
