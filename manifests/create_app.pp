# == Class: pm2::create_app
#
# install a nodejs app and run in pm2 
#
class pm2::create_app(
  $name            = '', 
  $app             = $name,
  $appversion      = 'latest',
  $path            = "/opt/nodejs/$name",
  $script          = "lib/app.js",              
  $args            = [],
  $env             = '',
  $install_root    = '/opt',
  $install_dir     = 'nodejs',
#  $node_dir        = '/usr/local/node/node-default',
  $deamon_user     = 'nodejs')
{

 $install_path = "$install_root/$install_dir"
 

  file { $path:
    ensure  => directory,
    owner   => $deamon_user,
    group   => $deamon_user,
    mode    => 750
  } 

  file { "$path/$appversion":
    ensure  => directory,
    owner   => $deamon_user,
    group   => $deamon_user,
    mode    => 750,
    require => File["$path"]
  } 
  
  exec { "npm install $app":
    command     => "npm install $app",
    path        => $::path,
    timeout     => 0, 
    cwd         => "$path/$appversion",
    require     => File["$path/$appversion"]
  }  

  exec {  "fixup $app":
    command     => "chown -Rf $deamon_user:$deamon_user '$path/$appversion'",
    timeout     => 0, 
    cwd         => "$path/$appversion",
    require     => Exec["npm install $app"]
  }

  file { "$path/pm2.json":
     ensure   => "present",
     owner    => $deamon_user,
     group    => $deamon_user,
     mode     => 0444,
     content  => template('pm2/pm2.json.erb'),
     require  => Exec["fixup $app"],
  }

   file { "/var/log/pm2/$name":
    ensure  => directory,
    owner   => $deamon_user,
    group   => $deamon_user,
    mode    => 755,
    require => File["$path/pm2.json"]
   }  
   
   file { "$path/logs":
    ensure  => 'link',
    target  => "/var/log/pm2/$name",
    owner   => $deamon_user,
    group   => $deamon_user,
    mode    => 755,
    require => File["/var/log/pm2/$name"]
   }
 
   file { "$path/pids":
    ensure  => 'link',
    target  => '/var/run/pm2',
    owner   => $deamon_user,
    group   => $deamon_user,
    require => File["$path/logs"]
   }
   
  # HACK: `pm2 reload` does NOT reload changes to the pm2.json file
  #       the only way to process changes in the pm2.json file is to delete and
  #       then start the app
  # BUG: bug in PM2 means have to set HOME variable for user 
  
  exec {  "pm2 delete $name":
    command     => "pm2 delete $name",
    timeout     => 0,
    path        => $::path,
    user        => $deamon_user,
    group       => $deamon_user, 
    environment => ["HOME=$install_root/$install_dir"],
    cwd         => "$path/current",
    onlyif      => "pm2 -m list | grep '\-\-\- $name'",
    require     => File["$path/pids"]
  }  

   file { "$path/current":
    ensure  => 'link',
    target  => "$path/$appversion",
    owner   => $deamon_user,
    group   => $deamon_user,
    require => Exec["pm2 delete $name"]
   }
  

  # now tell pm2 to startup using a cluster with as many nodes as CPUs
  # BUG: bug in PM2 means have to set HOME variable for user   
  exec {  "pm2 start '$path/pm2.json' --name '$name'":
    command     => "pm2 start '$path/pm2.json' --name '$name'",
    timeout     => 0,
    path        => $::path,
    user        => $deamon_user,
    environment => ["HOME=$install_root/$install_dir"],
    group       => $deamon_user, 
    cwd         => "$path/current",
    require     => File["$path/current"]    
  }    

}
