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
class cockpit(
  $useMock = true,
  $ensure  = true,
  $vcsRoot = '/opt/cockpit/checkout',
  $initFile = '/etc/init.d/cockpit',
  $rubyVersion = 'ruby-2.0.0-p0',
  $runAsUser   = 'elexis',
) {

  class { "cockpit::setup": ensure => $ensure, install_dir => "/home/$runAsUser"}

  # if !defined(User['elexis']) { user { 'elexis': ensure => present } }
  if ($ensure != absent ) {
    $pkg_ensure = present

    exec { 'bundle_trust_cockpit':
      command => "echo bundle install --gemfile $vcsRoot/Gemfile &> $vcsRoot/install.log",
      creates => "$vcsRoot/install.log",
      cwd => "/usr/bin",
      path => '/usr/local/bin:/usr/bin:/bin',
      require => [ Rbenv::Compile['cockpit/2.1.2'],
                  Vcsrepo[$vcsRoot],
                  Exec['build-dep ruby-bcrypt'],
                 ],
    }
    exec { 'build-dep ruby-bcrypt':
      command => "apt-get install build-dep ruby-bcryp uby-redcloth 2>&1| tee build_dep.log",
      creates => "$vcsRoot/build_dep.log",
      path => '/usr/local/bin:/usr/bin:/bin',
    }

    exec { 'gen_mockconfig':
      command => "bundle exec rake mock_scripts 2>&1| tee mock_scripts.log",
      creates => "$vcsRoot/mock_scripts.log",
      cwd => "$vcsRoot",
      path => '/usr/local/bin:/usr/bin:/bin',
      require =>  [ Vcsrepo[$vcsRoot],
                    Exec['bundle_trust_cockpit'], ],
    }
  }
  else {
    $pkg_ensure = absent
    notify{"ohne $initFile da $ensure und pkg $pkg_ensure ":}
  }

  file  { $initFile:
    content => template('cockpit/cockpit.init.erb'),
    ensure => $pkg_ensure,
    owner => 'root',
    group => 'root',
    mode  => 0754,
  }

  notify{"vcsRoot ist $vcsRoot": }
  vcsrepo {  "$vcsRoot":
      ensure => $pkg_ensure,
      provider => 'git',
      owner => $runAsUser,
      group => $runAsUser,
      source => "https://github.com/elexis/elexis-cockpit.git",
      require => [User[$runAsUser],],
  }
}


class cockpit::service(
  $ensure  = true,
) inherits cockpit
{
  if ($ensure != absent) {
    service { 'cockpit':
      ensure => running,
      enable => true,
      hasstatus => false,
      hasrestart => false,
      require =>  [ File["$cockpit::initFile"],
        Exec[ 'bundle_trust_cockpit', 'gen_mockconfig'] ],
    }
  } else {
    service { 'cockpit':
      ensure => stopped,
      enable => true,
      hasstatus => false,
      hasrestart => false,
    }
  }
}
