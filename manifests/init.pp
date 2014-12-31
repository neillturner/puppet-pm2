# == Class: pm2
#
# install nodejs and pm2 to be able run nodejs apps
#
class pm2(
  $npm_repository            = 'https://registry.npmjs.org',
  $npm_auth                  = '',
  $npm_always_auth           = false,
  $npm_email                 = 'test@test.org',
  $pm2_version               = 'latest',
  $install_root              = '/opt',
  $install_dir               = 'nodejs',
  $node_dir = '/usr/local/node/node-default',
  $deamon_user               = 'nodejs')
{

  $install_path = "${install_root}/${install_dir}"
  
  class { '::nodejs': }

  group { $deamon_user:
    ensure  => present,
    require => Class['nodejs'],
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
    mode    => '0750',
    require => [User[$deamon_user], Group[$deamon_user]]
  }
  
  file { "${node_dir}/etc":
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => File[$install_path],
  }

  # setup global npmrc config file
  file { "${node_dir}/etc/npmrc":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('pm2/npmrc.erb'),
    require => File["${node_dir}/etc"],
  }

  exec { 'install npm package pm2':
    command => "npm install --unsafe-perm -g pm2@${pm2_version}",
    path    => $::path,
    creates => "${node_dir}/bin/pm2",
    timeout => 0,
    require => File["${node_dir}/etc/npmrc"],
  }

  # TODO handle initialzing the `pm2 web` monitoring API
  exec { 'pm2 init':
    refreshonly => true,
    environment => ["HOME=${install_root}/${install_dir}"],
    command     => 'pm2 status',
  }

  service { 'pm2':
    ensure  => running,
    enable  => true,
    require => Exec['install npm package pm2'],
  }

  file { '/etc/init.d/pm2':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('pm2/pm2.init.erb'),
    notify  => Service['pm2'],
    require => Exec['install npm package pm2'],
  }

  file { "${install_root}/${install_dir}/deploy_app.sh":
    ensure  => file,
    owner   => $deamon_user,
    group   => $deamon_user,
    mode    => '0755',
    content => template('pm2/deploy_app.sh.erb'),
    require => File['/etc/init.d/pm2'],
  }

  file { "${install_root}/${install_dir}/deploy_test.sh":
    ensure  => file,
    owner   => $deamon_user,
    group   => $deamon_user,
    mode    => '0755',
    content => template('pm2/deploy_test.sh.erb'),
    require => File["${install_root}/${install_dir}/deploy_app.sh"]
  }
}
