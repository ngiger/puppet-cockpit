require 'spec_helper'
RSpec.configure do |c|
  c.hiera_config = 'spec/fixtures/hiera/hiera.yaml'
end

describe 'cockpit' do
  let(:facts) { WheezyFacts }
  context 'when using mustermann.yaml to set configuration values' do
    let(:params) { { } }
    let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
    it {
      should compile
      should compile.with_all_deps
  }
  end
end
