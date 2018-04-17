# @summary Base Sensu class
#
# This is the main Sensu class
#
# @param version Version of Sensu to install.  Defaults to `installed` to support
#   Windows MSI packaging and to avoid surprising upgrades.
#
# @param etc_dir Absolute path to the Sensu etc directory. Default:
# '/etc/sensu' and 'C:/opt/sensu' on windows.
#
# @param etc_dir_purge Boolean to determine if the etc_dir should be purged
# such that only Puppet managed files are present.
#
# @param manage_repo Boolean to determine if software repository for Sensu
# should be managed.
#
class sensu (
  String $version = 'installed',
  Stdlib::Absolutepath $etc_dir = $::osfamily ? {
    'windows' => 'C:/opt/sensu',
    default   => '/etc/sensu',
  },
  Boolean $etc_dir_purge = true,
  Boolean $manage_repo = true,
) {

  include ::sensu::agent

  file { 'sensu_etc_dir':
    ensure  => 'directory',
    path    => $etc_dir,
    purge   => $etc_dir_purge,
    recurse => $etc_dir_purge,
  }

  case $osfamily {
    'RedHat': {
      if $manage_repo == true {
        # TODO: change from nightly to stable once there are stable releases
        yumrepo { 'sensu_nightly':
          baseurl         => "https://packagecloud.io/sensu/nightly/el/${::operatingsystemmajrelease}/\$basearch",
          repo_gpgcheck   => 1,
          gpgcheck        => 0,
          enabled         => 1,
          gpgkey          => 'https://packagecloud.io/sensu/nightly/gpgkey',
          sslverify       => 1,
          sslcacert       => '/etc/pki/tls/certs/ca-bundle.crt',
          metadata_expire => 300,
          before          => Package['sensu-agent'],
        }
      }
    }
    default: {
      fail("Detected osfamily <${::osfamily}>. Only RedHat is supported.")
    }
  }
}
