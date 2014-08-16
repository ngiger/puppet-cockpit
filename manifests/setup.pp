class cockpit::setup(
  $ensure  = true,
  $install_dir = '/opt/dummy',
) inherits cockpit
{
  
  class { 'rbenv': install_dir => '/opt/rbenv' }
  rbenv::plugin { 'sstephenson/ruby-build': }
  rbenv::build { '2.1.2': global => true }
   
}
