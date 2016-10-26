# Class to install the MySQL Java connector
# borrowed from jira module
class confluence::mysql_connector (
  $version      = $confluence::mysql_connector_version,
  $product      = $confluence::mysql_connector_product,
  $format       = $confluence::mysql_connector_format,
  $installdir   = $confluence::mysql_connector_install,
  $downloadURL  = $confluence::mysql_connector_URL,
) {

  require staging

  $file = "${product}-${version}.${format}"

  if ! defined(File[$installdir]) {
    file { $installdir:
      ensure => 'directory',
      owner  => root,
      group  => root,
      before => Staging::File[$file]
    }
  }

  staging::file { $file:
    source  => "${downloadURL}/${file}",
    timeout => 300,
  } ->

  staging::extract { $file:
    target  => $installdir,
    creates => "${installdir}/${product}-${version}",
  } ->

  # symlinking (below) does not work when the <Resources allowLinking="true" />
  # is not set in tomcat context.xml so we'll copy it instead
  file { "${confluence::webappdir}/confluence/WEB-INF/lib/mysql-connector-java.jar":
    source => "${installdir}/${product}-${version}/${product}-${version}-bin.jar",
    ensure => present,
  }

# file { "${confluence::webappdir}/confluence/WEB-INF/lib/mysql-connector-java.jar":
#    ensure => link,
#    target => "${installdir}/${product}-${version}/${product}-${version}-bin.jar",
#  }

}
