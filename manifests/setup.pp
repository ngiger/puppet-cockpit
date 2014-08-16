class cockpit::setup(
  $ensure  = true,
  $install_dir = '/opt/dummy',
) inherits cockpit
{
    group { "$cockpit::runAsUser": 
      ensure => 'present',
    }

    user { "$cockpit::runAsUser":
      ensure => 'present',
      gid => $cockpit::runAsUser,
      managehome => false,
      home => "$install_dir",
      shell => "/bin/bash",
      password => "!!",
      require => Group[$cockpit::runAsUser],
    }

    file { "$install_dir":
      ensure => directory,
      owner => $cockpit::runAsUser,
      group => $cockpit::runAsUser,
      mode => '700',
      require => User[$cockpit::runAsUser],
    }

    file { "$install_dir/.bash_profile":
      ensure => 'present',
      owner => $cockpit::runAsUser,
      group => $cockpit::runAsUser,
      mode => '700',
      content => '. ~/.bashrc',
      require => [User[$cockpit::runAsUser], File["$install_dir"] ],
  }   

    file { "$install_dir/.bashrc":
      ensure => link,
      owner => $cockpit::runAsUser,
      group => $cockpit::runAsUser,
      mode => '700',
      target => '/etc/skel/.bashrc',
      require => [User[$cockpit::runAsUser], File["$install_dir"] ],
  }   

    rbenv::install { $cockpit::runAsUser:
      home => $install_dir,
      require => [File[ "$install_dir/.bash_profile"], User[$cockpit::runAsUser]],
    }

    rbenv::compile { 'cockpit/2.1.2':
      user => $cockpit::runAsUser,
      home => $install_dir,
      ruby => '2.1.2',
      global => true,
      require => Rbenv::Install[$cockpit::runAsUser],
    }

    rbenv::plugin { "rbenv-bundler":
      user => $cockpit::runAsUser,
      home => $install_dir,
      source => 'git://github.com/carsomyr/rbenv-bundler.git',
      require => [File[ "$install_dir/.bash_profile"], Rbenv::Install[$cockpit::runAsUser]],
    }

}
