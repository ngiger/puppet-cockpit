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
  $ensure  = false,
  $use_systemd = true

) {
  if !defined(Class['cockpit']) {class{'cockpit':  ensure => true } }
  $cockpit_name     = "elexis_cockpit"
  $managed_note     = "managed by puppet ngiger/cockpit/service.pp"

  if ( $cockpit::useMock ) {
    $export_mock = "export COCKPIT_CONFIG=mock_config.yaml"
  }
  if ($ensure) {
    $vcsRoot = $::cockpit::vcsRoot
    $runAsUser = $cockpit::runAsUser
    package{'bundler': ensure => present,
      provider => gem,
    }

    if ($use_systemd) {
      $systemd_packages = [ 'systemd', 'systemd-sysv',]
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
User=$runAsUser
Group=$runAsUser
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
      # service{'cockpit':
      #   ensure => running,
      #   provider => systemctl,
      #   require => File['/etc/systemd/system/cockpit.service'],
      # }
    } else { # system-v init
      $initFile = '/etc/init.d/cockpit'
      file  { $initFile:
        content => template('cockpit/cockpit.init.erb'),
        owner => 'root',
        group => 'root',
        mode  => 0754,
      }

      exec{'update-rc_cockpit':
        command => '/usr/sbin/update-rc.d cockpit defaults',
        subscribe => File[$initFile],
        require   => File[$initFile],
      }
      service{'cockpit':
        ensure => running,
        provider => debian,
        manifest => $initFile,
        status   => '/bin/ps -ef | /bin/grep "ruby cockpit"',
        require => [Exec['gen_mockconfig', 'bundle_trust_cockpit'], File[$initFile, '/etc/sudoers.d/cockpit']],
      }
    }

    file{'/etc/sudoers.d/cockpit':
      ensure => present,
      content => "# $managed_note
$runAsUser ALL=NOPASSWD:/sbin/shutdown
",
    }

    file{"$vcsRoot/start.sh":
      content => "#!/bin/bash -v
cd  $vcsRoot
echo \$PATH
ruby -v
$export_mock
bundle install --deployment
bundle exec ruby elexis-cockpit.rb 2>&1
",
      owner =>  $runAsUser,
      group =>  $runAsUser,
      mode    => 0755,
      require => [ Package['bundler']],
      # require => File["$vcsRoot"],
    }

    $build_deps = ['ruby-redcloth', 'ruby-sqlite3', 'ruby-dev', 'libxml2-dev', 'libxslt1-dev']
    ensure_packages[$build_deps]
    exec { 'bundle_trust_cockpit':
      command => "bundle install --gemfile $vcsRoot/Gemfile && touch $vcsRoot/bundle_trust_cockpit.done",
      creates => "$vcsRoot/bundle_trust_cockpit.done",
      cwd => "/usr/bin",
      path => '/usr/local/bin:/usr/bin:/bin',
      require => [ # Rbenv::Build['2.1.2'],
                  Vcsrepo[$vcsRoot],
                  Package['bundler', $build_deps],
                  Apt::Builddep[$build_deps],
                 ],
    }

    exec { 'gen_mockconfig':
      command => "bundle exec rake mock_scripts && touch $vcsRoot/gen_mockconfig.done",
      creates => "$vcsRoot/gen_mockconfig.done",
      cwd => "$vcsRoot",
      path => '/usr/local/bin:/usr/bin:/bin',
      require =>  [ Vcsrepo[$vcsRoot],
                    Package['bundler', $build_deps],
                    Exec['bundle_trust_cockpit'], ],
    }
    require apt
    apt::builddep{$build_deps: }
  }
}