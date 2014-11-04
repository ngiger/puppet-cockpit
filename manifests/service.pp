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
  $use_systemd = true

) {
  if !defined(Class['cockpit']) {class{'cockpit':  ensure => true } }
  $cockpit_runner = "${cockpit::local_bin}/start_elexis_cockpit.sh"
  $cockpit_name     = "elexis_cockpit"
  $cockpit_run      = "/etc/$cockpit_name/run"
  $managed_note     = "managed by puppet ngiger/cockpit/service.pp"

  if ( $cockpit::useMock ) {
    $export_mock = "export COCKPIT_CONFIG=mock_config.yaml"
  }
# mkdir /etc/systemd/system
# cp cockpit.service /etc/systemd/system/
# apt-get install systemd
#  apt-get install systemd-sysv
# systemctl daemon-reload
# systemctl restart cockpit
# rm /etc/init.d/dockpit
  if ($ensure != absent) {
    $vcsRoot = $::cockpit::vcsRoot
    package{'bundler': ensure => present,
      provider => gem,
    }

    if ($use_systemd) {
      $systemd_packages = [ 'systemd-sysv', 'systemd' ]
      ensure_packages($systemd_packages)
      file{'/etc/init.d/cockpit': ensure => absent} # avoid collision with System-V init
      file{"/etc/$cockpit_name":  ensure => absent, recurse => true, force => true}
      file{'/etc/systemd/system/cockpit.service':
        content => "# $managed_note
[Unit]
Description =  Elexis-Cockpit simple Sinatra Web page for some administration work
After = NetworkManager-wait-online.service network.target syslog.target

[Service]
ExecStart = $vcsRoot/start.sh
User=$cockpit::runAsUser
Group=$cockpit::runAsUser
PIDFile = /var/run/cockpit.pid
Restart = on-abort
StartLimitInterval = 60
StartLimitBurst = 10

[Install]
WantedBy = multi.user.target
",
      require => [ Package[$systemd_packages], Vcsrepo[$vcsRoot], ],
      }
      exec{'restart_cockpit_via_systemctl':
        command => '/bin/systemctl daemon-reload && /bin/systemctl restart cockpit',
        subscribe => File['/etc/systemd/system/cockpit.service'],
      }
    } else { # system-v init
      file  { $initFile:
        content => template('cockpit/cockpit.init.erb'),
        ensure => $pkg_ensure,
        owner => 'root',
        group => 'root',
        mode  => 0754,
      }

      file{"$cockpit_run":
      content => "#!/bin/bash
sudo su -l $cockpit::runAsUser $vcsRoot/start.sh 2>&1 | tee /var/log/$cockpit::runAsUser.log
",
        owner =>  $cockpit::runAsUser,
        group =>  $cockpit::runAsUser,
        mode    => 0755,
        require => File["/etc/$cockpit_name", "$vcsRoot/start.sh"],
      }
      daemontools::service {'cockpit':
        ensure  => running,
        command => "$vcsRoot/start.sh",
        logpath => '/var/log/$cockpit',
      }
      file{"/etc/$cockpit_name": ensure => directory}
    }

    file{"$vcsRoot/start.sh":
      content => "#!/bin/bash -v
cd  $vcsRoot
echo \$PATH
ruby -v
$export_mock
bundle install
bundle exec ruby elexis-cockpit.rb 2>&1
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
  }
}