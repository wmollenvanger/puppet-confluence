# == Class: confluence
#
# Install confluence, See README.md for more.
#
class confluence (

  # JVM Settings
  $javahome     = undef,
  $jvm_xms      = '256m',
  $jvm_xmx      = '1024m',
  $jvm_permgen  = '256m',
  $java_opts    = '',

  # Confluence Settings
  $version      = '5.7.1',
  $product      = 'confluence',
  $format       = 'tar.gz',
  $installdir   = '/opt/confluence',
  $homedir      = '/home/confluence',
  $user         = 'confluence',
  $group        = 'confluence',
  $uid          = undef,
  $gid          = undef,
  $manage_user  = true,
  $shell        = '/bin/true',

  # Database Settings
  # not fully used atm
  $db                      = 'mysql',
  $dbuser                  = 'confluence',
  $dbpassword              = 'mypassword',
  $dbserver                = 'localhost',
  $dbname                  = 'confluence',
  $dbport                  = '3306',
  #$dbdriver                = 'org.postgresql.Driver',
  #$dbtype                  = 'postgres72',
  #$dburl                   = undef,
  #$poolsize                = '20',
  #$dbschema                = 'public',

  # MySQL Connector Settings
  $mysql_connector_manage  = true,
  $mysql_connector_version = '5.1.40',
  $mysql_connector_product = 'mysql-connector-java',
  $mysql_connector_format  = 'tar.gz',
  $mysql_connector_install = '/opt/MySQL-connector',
  $mysql_connector_URL     = 'http://dev.mysql.com/get/Downloads/Connector-J/',

  # Misc Settings
  $download_url = 'http://www.atlassian.com/software/confluence/downloads/binary',
  $checksum     = undef,

  # Choose whether to use puppet-staging, or puppet-archive
  $deploy_module = 'archive',

  # Manage confluence server
  $manage_service = true,

  # Tomcat Tunables
  # Should we use augeas to manage server.xml or a template file
  $manage_server_xml   = 'augeas',
  $tomcat_port         = 8090,
  $tomcat_max_threads  = 150,
  $tomcat_accept_count = 100,
  # Reverse https proxy setting for tomcat
  $tomcat_proxy = {},
  # Any additional tomcat params for server.xml
  $tomcat_extras = {},
  $context_path  = '',

  # Command to stop confluence in preparation to updgrade. This is configurable
  # incase the confluence service is managed outside of puppet. eg: using the
  # puppetlabs-corosync module: 'crm resource stop confluence && sleep 15'
  $stop_confluence = 'service confluence stop && sleep 15',

  # Enable confluence version fact for running instance
  # This required for upgrades
  $facts_ensure = 'present',

  # Enable SingleSignOn via Crowd

  $enable_sso = false,
  $application_name = 'crowd',
  $application_password = '1234',
  $application_login_url = 'https://crowd.example.com/console/',
  $crowd_server_url = 'https://crowd.example.com/services/',
  $crowd_base_url = 'https://crowd.example.com/',
  $session_isauthenticated = 'session.isauthenticated',
  $session_tokenkey = 'session.tokenkey',
  $session_validationinterval = 5,
  $session_lastvalidation = 'session.lastvalidation',
) {

  validate_re($version, '^(?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)(|[a-z])$')
  validate_absolute_path($installdir)
  validate_absolute_path($homedir)
  validate_bool($manage_user)

  validate_re($manage_server_xml, ['^augeas$', '^template$' ],
    'manage_server_xml must be "augeas" or "template"')
  validate_hash($tomcat_proxy)
  validate_hash($tomcat_extras)

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  $webappdir    = "${installdir}/atlassian-${product}-${version}"

  if $::confluence_version {
    # If the running version of CONFLUENCE is less than the expected version of CONFLUENCE
    # Shut it down in preparation for upgrade.
    if versioncmp($version, $::confluence_version) > 0 {
      notify { 'Attempting to upgrade CONFLUENCE': }
      exec { $stop_confluence: before => Anchor['confluence::start'] }
    }
  }

  if $javahome == undef {
    fail('You need to specify a value for javahome')
  }

  anchor { 'confluence::start': } ->
  class { '::confluence::facts': } ->
  class { '::confluence::install': } ->
  class { '::confluence::config': } ~>
  class { '::confluence::service': } ->
  anchor { 'confluence::end': }

  if ($enable_sso) {
    class { '::confluence::sso':
    }
  }
}
