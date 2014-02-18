#
# Installs and configureds oozie server.  If database is set,
# The oozie database will also be created by the database class.
#
# See: http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.1/CDH4-Installation-Guide/cdh4ig_topic_17_6.html
#
# == Parameters
#
# $jdbc_database                 - Oozie database name.                   Default: oozie
# $jdbc_username                 - Oozie JDBC username.                   Default: oozie
# $jdbc_password                 - Oozie JDBC password.                   Default: oozie
# $jdbc_host                     - Oozie JDBC hostname.                   Default: localhost
# $jdbc_port                     - Oozie JDBC port.                       Default: 3306
# $jdbc_driver                   - Oozie JDBC driver class name.          Default: com.mysql.jdbc.Driver
# $smtp_host                     - SMTP host for email notifications.
#                                  Default: undef, SMTP will not be configured.
# $smtp_port                     - SMTP port.                             Default: 25
# $smtp_from_email               - Sender email address of notifications. Default: undef
# $smtp_username                 - Username for SMTP authentication.      Default: undef
# $smtp_password                 - Password for SMTP authentication.      Default: undef
#
# $authorization_service_security_enabled -  If disabled any user can manage Oozie
#                                            system and manage any job.  Default: true
#
class oozie::server (
    $database                               = $oozie::defaults::database,

    $jdbc_database                          = $oozie::defaults::jdbc_database,
    $jdbc_username                          = $oozie::defaults::jdbc_username,
    $jdbc_password                          = $oozie::defaults::jdbc_password,
    $jdbc_host                              = $oozie::defaults::jdbc_host,
    $jdbc_port                              = $oozie::defaults::jdbc_port,
    $jdbc_driver                            = $oozie::defaults::jdbc_driver,
    $jdbc_protocol                          = $oozie::defaults::jdbc_protocol,

    $smtp_host                              = $oozie::defaults::smtp_host,
    $smtp_port                              = $oozie::defaults::smtp_port,
    $smtp_from_email                        = $oozie::defaults::smtp_from_email,
    $smtp_username                          = $oozie::defaults::smtp_username,
    $smtp_password                          = $oozie::defaults::smtp_password,

    $authorization_service_security_enabled = $oozie::defaults::authorization_service_security_enabled,

    $oozie_site_template                    = $oozie::defaults::oozie_site_template,
    $oozie_env_template                     = $oozie::defaults::oozie_env_template,

) inherits oozie::defaults
{
    #XXX Set requirements for hadoop client class
    # Also require oozie client class.
    Class['oozie::client']  -> Class['oozie::server']

    package { 'oozie':
        ensure => 'installed',
    }

    if (!defined(Package['libjs-extjs'])) {
        package { 'libjs-extjs':
            ensure => 'installed',
        }
    }
    # Symlink extjs install path into /var/lib/oozie.
    # This is required for the Oozie web interface to work.
    file { '/var/lib/oozie/extjs':
        ensure  => 'link',
        target  => '/usr/share/javascript/extjs',
        require => [Package['oozie'], Package['libjs-extjs']],
    }

    # For MR only
    $catalina_base = '/usr/lib/oozie/oozie-server-0.20'

    # Ensure that Catalina working directories exist.
    # Without these, oozie will log the error:
    # "The specified scratchDir is unusable: /usr/lib/oozie/oozie-server/work/Catalina/localhost/_"
    file { ["${catalina_base}/work",
            "${catalina_base}/work/Catalina",
            "${catalina_base}/work/Catalina/localhost"]:
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['oozie'],
    }
    file { ["${catalina_base}/work/Catalina/localhost/_",
            "${catalina_base}/work/Catalina/localhost/oozie"]:
        ensure  => 'directory',
        owner   => 'oozie',
        group   => 'oozie',
        mode    => '0755',
        require => File["${catalina_base}/work/Catalina/localhost"],
    }

    # Extract and install Oozie ShareLib into HDFS
    # at /user/oozie/share

    # sudo -u hdfs hadoop fs -mkdir /user/oozie
    # sudo -u hdfs hadoop fs -chmod 0775 /user/oozie
    # sudo -u hdfs hadoop fs -chown hive:hadoop /user/oozie

    # Put oozie folder and sharelib into HDFS:
    # For MR only
    $oozie_sharelib_archive = '/usr/lib/oozie/oozie-sharelib.tar.gz'
    $oozie_sharelib_tmpdir = inline_template('/tmp/oozie_sharelib_install.<%= rand() %>')
    exec {
        'oozie_directory':
            command => "/usr/bin/hadoop fs -mkdir /user/oozie && /usr/bin/hadoop fs -chmod 0755 /user/oozie && /usr/bin/hadoop fs -chown oozie:hadoop /user/oozie",
            unless  => "/usr/bin/hadoop fs -test -e /user/oozie",
            user    => 'hdfs';

        'oozie_sharelib_install':
        command => "\
/bin/mkdir -p ${oozie_sharelib_tmpdir}                                   && \
/bin/tar -C ${oozie_sharelib_tmpdir} -xzf ${oozie_sharelib_archive}      && \
/usr/bin/hadoop fs -put ${oozie_sharelib_tmpdir}/share /user/oozie/share && \
/bin/rm -rf ${oozie_sharelib_tmpdir}",
        # don't run this command if /user/oozie/share already exists in HDFS.
        unless  => '/usr/bin/hadoop fs -ls /user/oozie | grep -q /user/oozie/share',
        user    => 'oozie',
        require => Exec['oozie_directory'],
    }

    file { '/etc/oozie/conf/oozie-site.xml':
        content => template($oozie_site_template),
        mode    => '0440',  # has database pw in it, shouldn't be world readable.
        owner   => 'root',
        group   => 'oozie',
        require => Package['oozie'],
    }
    file { '/etc/oozie/conf/oozie-env.sh':
        content => template($oozie_env_template),
        mode    => '0444',
        owner   => 'root',
        group   => 'oozie',
        require => Package['oozie'],
    }

    # Set up the database
    $database_class = "oozie::database::mysql"
    if ($database) {
        class { $database_class: }
        # Make sure the $database_class is included and set up
        # before we start the oozie server service
        Class[$database_class] -> Service['oozie']
    }

    service { 'oozie':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        subscribe  => [
            File['/etc/oozie/conf/oozie-site.xml'],
            File['/etc/oozie/conf/oozie-env.sh']
        ],
        require    => [
            File['/var/lib/oozie/extjs'],
            # Package['libcnative-1'],
            File["${catalina_base}/work/Catalina/localhost/oozie"],
            File["${catalina_base}/work/Catalina/localhost/_"]
        ],
    }
}
