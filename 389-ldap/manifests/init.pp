class 389-ldap ($dc = "dc=search,dc=km", $password = "secret")  {

    file {
        "/etc/dirsrv/config.ini":
            mode => 0640,
            owner => root,
            group => root,
            require => Package["389-ds"],
            content => template("389-ldap/config.ini.erb");
    }

    
    package {
        "389-ds":
            ensure => installed;
    }

    service {
        "dirsrv":
            enable => true,
            hasstatus => true,
            ensure => "running",
            require => Exec["initial-config"];
        "dirsrv-admin":
            enable => true,
            hasstatus => true,
            ensure => "running",
            require => Exec["initial-config"];
    }
            
    exec {
        "initial-config":
            command => '/usr/sbin/setup-ds-admin.pl --silent --file /etc/dirsrv/config.ini',
            require => [File["/etc/dirsrv/config.ini"], Package["389-ds"]],
            creates => "/etc/dirsrv/slapd-$hostname";
    }
}
