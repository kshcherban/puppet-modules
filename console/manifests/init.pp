class console {

    file {
        '/etc/init/ttyS0.conf':
            mode => 0644,
            owner => root,
            group => root,
            source => 'puppet:///modules/console/ttyS0.conf',
            ensure => present;

        '/etc/securetty':
            mode => 0600,
            owner => root,
            group => root,
            source => 'puppet:///modules/console/securetty',
            ensure => present;
    }


    exec {
        'startty':
            command => '/sbin/initctl start ttyS0',
            require => File['/etc/init/ttyS0.conf'],
            unless => '/bin/ps x|/bin/grep ttyS0|/bin/grep -v grep';
    }
}
