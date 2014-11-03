# == Class: cockpit
#
# This class installs the Elexis-Cockpit project.
# By default it generates mock scripts and instals the Sinatra
# application listening on port 9393
#
# === Parameters
#
# none
#
# === Variables
# useMock = default true. generates mockscripts. This is safe
#         as we the app will usually to heavy stuff like rebooting the
#         server
# ensure  = present or absent. If absent will purge the repository, too
# vcsRoot = where to install the checkout copy of the elexis-cockpit app
# initFile = the init script
# rubyVersion = The ruby version to install. Must match the Gemfile
#
# === Examples
#
#  class { "cockpit::service": initFile = '/my/Personal/Path', }
#  class { "cockpit::service":  }
#
# === Authors
#
# Niklaus Giger <niklaus.giger@member.fsf.org>
#
# === Copyright
#
# Copyright 2013 Niklaus Giger <niklaus.giger@member.fsf.org>
#
class cockpit::service(
  $ensure  = true,

) {
  if !defined(Class['cockpit']) {class{'cockpit':  ensure => true } }
  $cockpit_runner = "${cockpit::local_bin}/start_elexis_cockpit.sh"
  $cockpit_name     = "elexis_cockpit"
  $cockpit_run      = "/etc/$cockpit_name/run"

  if ( $cockpit::useMock ) {
    $export_mock = "export COCKPIT_CONFIG=mock_config.yaml"
  }

  if ($ensure != absent) {
    $vcsRoot = $::cockpit::vcsRoot

    file{"/etc/$cockpit_name": ensure => directory}
    package{'bundler': ensure => present,
      provider => gem,
    }
    file{"$vcsRoot/start.sh":
      content => "#!/bin/bash -v
cd  $vcsRoot
# export PATH=/opt/rbenv/shims:\$PATH
echo \$PATH
ruby -v
$export_mock
bundle install
ruby elexis-cockpit.rb 2>&1
",
      owner =>  $cockpit::runAsUser,
      group =>  $cockpit::runAsUser,
      mode    => 0755,
      require => [ Package['bundler']],
      # require => File["$vcsRoot"],
    }

    $build_deps = ['ruby-redcloth', 'ruby-sqlite3']
    exec { 'bundle_trust_cockpit':
      command => "echo bundle install --gemfile $vcsRoot/Gemfile &> $vcsRoot/install.log",
      creates => "$vcsRoot/install.log",
      cwd => "/usr/bin",
      path => '/usr/local/bin:/usr/bin:/bin',
      require => [ # Rbenv::Build['2.1.2'],
                  Vcsrepo[$vcsRoot],
                  Apt::Builddep[$build_deps],
                 ],
    }

    exec { 'gen_mockconfig':
      command => "bundle exec rake mock_scripts 2>&1| tee mock_scripts.log",
      creates => "$vcsRoot/mock_scripts.log",
      cwd => "$vcsRoot",
      path => '/usr/local/bin:/usr/bin:/bin',
      require =>  [ Vcsrepo[$vcsRoot],
                    Exec['bundle_trust_cockpit'], ],
    }
    class { 'apt':  always_apt_update    => true,}
    apt::builddep{$build_deps: }

    file{"$cockpit_run":
     content => "#!/bin/bash
sudo su -l $cockpit::runAsUser $vcsRoot/start.sh 2>&1 | tee /var/log/$cockpit::runAsUser.log
",
      owner =>  $cockpit::runAsUser,
      group =>  $cockpit::runAsUser,
      mode    => 0755,
      require => File["/etc/$cockpit_name", "$vcsRoot/start.sh"],
    }
    daemontools::service {'xxx':
  ensure  => running,
  command => "$vcsRoot/start.sh",
  logpath => '/var/log/$cockpit',
}
  } else {
    # file{"$cockpit_run": ensure => absent, }
 daemontools::service {'xxx':
  ensure  => absent,
  command => "$vcsRoot/start.sh",
  logpath => '/var/log/$cockpit',
}
if (false) {
    service { $cockpit_name:
      ensure => running,
      enable => true,
      hasstatus => false,
      provider => daemontools,
      hasrestart => false,
      require =>  [ File["$cockpit::initFile", $cockpit_run],
        # Rbenv::Build['2.1.2'],
        Exec[ 'bundle_trust_cockpit', 'gen_mockconfig'] ],
    }
service {$cockpit_name:
      ensure => stopped,
      provider => daemontools,
        enable => true,
      hasstatus => false,
      hasrestart => false,
    }
}
  }
}