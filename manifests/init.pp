# == Class: pm2
#
# install nodejs and pm2 to be able run nodejs apps
#
class pm2(
  $npm_repository            = "https://registry.npmjs.org",
  $npm_auth                  = '',
  $npm_always_auth           = false,
  $pm2_version               = "latest",
  $install_root              = '/opt',
  $install_dir               = 'nodejs',
  $deamon_user               = 'nodejs')
{

 $install_path = "$install_root/$install_dir"
 
 class { 'epel': }  

 class { '::nodejs':
   require => Class['epel'],
 }
 
  # set directory of npm and pm2 
  case $::osfamily {
      'RedHat': {
        $npm_dir = '/usr'
        $pm2_dir = '/usr'
        $npmrc_dir = '/usr'
      }
      'Debian': {
        $npm_dir = '/usr'
        $pm2_dir = '/usr/local'
        $npmrc_dir = ''
        # the nodejs module scripts don't always install npm on ubuntu 
        # so make sure the npm package is installed. 
        package { 'npm' : 
           ensure    => installed,
           require   => Class['::nodejs'],
        }          
       }     
      default: {
        $npm_dir = '/usr'
        $pm2_dir = '/usr'
        $npmrc_dir = '/usr'
      }
  }
 
 exec { 'upgrade npm':
  command     => "$npm_dir/bin/npm i --unsafe-perm -g npm",
  timeout     => 0, 
  require     => Package['npm']
}   

  group { $deamon_user:
    ensure => present,
    require  => Exec['upgrade npm'],
  }

  user { $deamon_user:
    ensure     => present,
    gid        => $deamon_user,
    managehome => true,
    shell      => '/bin/bash',
    home       => $install_path,
    groups     => [$deamon_user],    
    require    => Group[$deamon_user]
  }
  
  file { $install_path:
    ensure  => directory,
    owner   => $deamon_user,
    group   => $deamon_user,
    mode    => 750,
    require => [User[$deamon_user], Group[$deamon_user]]
  } 
 
  # setup global npmrc config file
  file { "$npmrc_dir/etc/npmrc":
       ensure   => "present",
       owner    => $deamon_user,
       group    => $deamon_user,
       mode     => 0755,
       content  => template('pm2/npmrc.erb'),
       require  => File[$install_path],
 }
  
exec { 'install npm package pm2': 
  command  => "$npm_dir/bin/npm install --unsafe-perm -g pm2@$pm2_version",
  creates   => "$pm2_dir/lib/node_modules/pm2",
  timeout    => 0,
  require  =>  File["$npmrc_dir/etc/npmrc"] 
}

# TODO handle initialzing the `pm2 web` monitoring API
exec { 'pm2 init':
  refreshonly => true,
  environment => ["HOME=$install_root/$install_dir"],
  command     => "pm2 status",
}

service { 'pm2':
  ensure   => "running",
  enable   => "true",
  require  => Exec['install npm package pm2'],
} 

file { "/etc/init.d/pm2":
     ensure   => "present",
     owner    => "root",
     group    => "root",
     mode     => 0750,
     content  => template('pm2/pm2.init.erb'),
     notify   => Service['pm2'],
     require  => Exec['install npm package pm2'],
 }
 
}