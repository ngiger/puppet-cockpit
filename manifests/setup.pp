class cockpit::setup(
  $ensure  = false,
  $install_dir = '/opt/dummy',
) inherits cockpit
{
  if ($ensure == true || $ensure == present) {
    #class { 'rbenv': install_dir => '/opt/rbenv' }
    #rbenv::plugin { 'sstephenson/ruby-build': }
    #rbenv::build { '2.1.2': global => true }
  }
}
