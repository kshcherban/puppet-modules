class snoopy (
    $installed  = true,
    $logger     = "syslog-ng",
    $logfile    = "/var/log/snoopy.log",
    ) {
    if $installed {
        package { "snoopy":
            ensure => 'installed'
        }
        Exec {
            require => Package['snoopy']
        }
        exec { "snoopy_add_preload":
            command     => "/bin/echo '/lib64/snoopy.so' >> /etc/ld.so.preload",
            unless      => "/bin/grep snoopy /etc/ld.so.preload"
        }
        file { "/etc/logrotate.d/snoopy":
            content => template('snoopy/logrotate.conf.erb'),
        }
        # Process logging
        if $logger == 'syslog-ng' {
            file { "/etc/syslog-ng/conf.d/snoopy.conf":
                content => template('snoopy/syslog-ng.conf.erb'),
                alias   => "logger",
            }
        }
        exec { "logger-restart":
            command     => "/etc/init.d/$logger restart",
            subscribe   => File["logger"],
            refreshonly => true,
        }

    } else {
        package { "snoopy":
            ensure => 'absent'
        }
        exec { "snoopy_del_preload":
            command     => "/bin/sed -i '/snoopy/d' /etc/ld.so.preload",
            onlyif      => "/bin/grep snoopy /etc/ld.so.preload"
        }
        file { "/etc/logrotate.d/snoopy":
            ensure => 'absent',
        }
        if $logger == 'syslog-ng' {
            file { "/etc/syslog-ng/conf.d/snoopy.conf":
                ensure => 'absent',
            }
        }
    }
}
