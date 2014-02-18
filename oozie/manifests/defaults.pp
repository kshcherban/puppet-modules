# == Class cdh4::oozie::defaults
#
class oozie::defaults {
    $database                               = 'mysql'

    $jdbc_driver                            = 'com.mysql.jdbc.Driver'
    $jdbc_protocol                          = 'mysql'
    $jdbc_database                          = 'oozie'
    $jdbc_host                              = 'localhost'
    $jdbc_port                              = 3306
    $jdbc_username                          = 'oozie'
    $jdbc_password                          = 'oozie'

    $smtp_host                              = undef
    $smtp_port                              = 25
    $smtp_from_email                        = undef
    $smtp_username                          = undef
    $smtp_password                          = undef

    $authorization_service_security_enabled = false

    # Default puppet paths to template config files.
    # This allows us to use custom template config files
    # if we want to override more settings than this
    # module yet supports.
    $oozie_site_template                    = 'oozie/oozie-site.xml.erb'
    $oozie_env_template                     = 'oozie/oozie-env.sh.erb'
}
