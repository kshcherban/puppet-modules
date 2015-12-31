class ldap389 (
    $dc       = 'dc=search,dc=km',
    $password = 'secret',
    $instance = $hostname,
)  {
    case $osfamily {
        'Debian': {
            $command = 'setup-ds-admin'
            $user = 'dirsrv'
        }
        'RedHat': {
            $command = 'setup-ds-admin.pl'
            $user = 'nobody'
        }
        default: {
            $command = 'setup-ds-admin.pl'
            $user = 'nobody'
        }
    }

    file {
        '/etc/dirsrv/config.ini':
            mode => 0640,
            owner => root,
            group => root,
            require => Package['389-ds'],
            content => template('ldap389/config.ini.erb');
    }

    package {
        '389-ds':
            ensure => installed;
    }

    service {
        'dirsrv':
            enable => true,
            hasstatus => true,
            ensure => 'running',
            require => Exec['initial-config'];
        'dirsrv-admin':
            enable => true,
            hasstatus => true,
            ensure => 'running',
            require => Exec['initial-config'];
    }

    exec {
        'initial-config':
            command => "/usr/sbin/${command} --silent --file /etc/dirsrv/config.ini",
            require => [File['/etc/dirsrv/config.ini'], Package['389-ds']],
            creates => "/etc/dirsrv/slapd-${instance}";
    }
}
