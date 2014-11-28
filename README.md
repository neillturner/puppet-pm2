puppet-pm2
==========

Puppet Module to deploy a nodejs application using PM2 

This is a pretty hacky first version. 
It relies on puppet module willdurand/nodejs to install nodejs and npm.
It would be good to make the create_app a provider called pm2_app.
It would be better to use the nodejs::npm provider instead of execing npm install etc.  



Minimal Usage: 
=============

     class { 'pm2': }

     class { 'pm2::create_app':
       name    => 'my-nodejs-app',
       require => Class['pm2']
     } 
 

Detailed Usage:
===============

     class { 'pm2':
       npm_repository    => "https://registry.npmjs.org",
       npm_auth          => 'Ashtyhy=+as',
       npm_always_auth   => true,
       pm2_version       => "latest",
       install_root      => '/opt',
       install_dir       => 'nodejs',
       deamon_user       => 'nodejs',  
     }

     class { 'pm2::create_app':
       name            => 'my-nodejs-app',
       app             => 'myapp',
       appversion      => 'latest',
       path            => "/opt/nodejs/myapp",
       script          => "lib/app.js",              
       args            => [],
       env             => {},
       install_root    => '/opt',
       install_dir     => 'nodejs',
       deamon_user     => 'nodejs',     
       require => Class['pm2']
     } 
 
 Nodejs Configuration: 
 ====================

 assuming using puppet 3.x with hiera then nodejs can be configured by setting the parameters in hiera:

 nodejs::version:          'stable'
 nodejs::target_dir:       '/usr/local/bin'
 nodejs::with_npm:         true
 nodejs::make_install:     true
 nodejs::create_symlinks:  false

