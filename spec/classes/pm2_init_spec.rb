require 'spec_helper'

describe "pm2" do
  let(:facts) { 
     {:osfamily => 'RedHat',
     :operatingsystem => 'CentOS',
     :operatingsystemrelease => '6',
	 :concat_basedir         => '/foo',
     }
  }
  it { should create_class('nodejs')}
end


