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
  $ensure  = false,
  $vcsRoot = '/opt/cockpit/checkout',
  $initFile = '/etc/init.d/cockpit',
  $rubyVersion = 'ruby-2.0.0-p0',
  $runAsUser   = 'cockpit',
) {
  if ($ensure) {
    class { "cockpit::setup": ensure => $ensure, install_dir => "/home/$runAsUser"}
    if ($ensure != absent ) {
      user { "$runAsUser":  ensure => present, }
      $pkg_ensure = present
    }
    else {
      $pkg_ensure = absent
      notify{"ohne $initFile da $ensure und pkg $pkg_ensure ":}
      user { "$runAsUser":  ensure => $ensure, }
    }

    file  { $initFile:
      content => template('cockpit/cockpit.init.erb'),
      ensure => $pkg_ensure,
      owner => 'root',
      group => 'root',
      mode  => 0754,
    }

    vcsrepo {  "$vcsRoot":
        ensure => $pkg_ensure,
        provider => 'git',
        owner => $runAsUser,
        group => $runAsUser,
        source => "https://github.com/elexis/elexis-cockpit.git",
        require => [User[$runAsUser],],
    }
	}
}
