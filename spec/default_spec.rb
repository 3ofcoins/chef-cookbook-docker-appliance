require 'chefspec'

describe 'docker-appliance::default' do
  let (:chef_run) { ChefSpec::ChefRunner.new.converge 'docker-appliance::default' }
  it 'should do something' do
    pending 'Your recipe examples go here.'
  end
end
