require 'aruba/cucumber'
require 'producer/core/testing/cucumber'

GEMRC = "gem: --no-ri --no-rdoc\n".freeze

Before('@sshd_gem_env') do
  write_file '.gemrc', GEMRC

  if ENV.key? 'TRAVIS'
    ssh_rc = <<-eoh
export GEM_HOME=#{ENV['GEM_HOME']}
export GEM_PATH=#{ENV['GEM_PATH']}
export MY_RUBY_HOME=#{ENV['MY_RUBY_HOME']}
export PATH=#{ENV['PATH']}
export RUBYLIB=#{ENV['RUBYLIB']}
export rvm_autoupdate_flag=#{ENV['rvm_autoupdate_flag']}
export rvm_bin_path=#{ENV['rvm_bin_path']}
export rvm_path=#{ENV['rvm_path']}
export rvm_prefix=#{ENV['rvm_prefix']}
export rvm_silence_path_mismatch_check_flag=#{ENV['rvm_silence_path_mismatch_check_flag']}
export rvm_version="#{ENV['rvm_version']}"
export RAILS_ENV=production
rvm use #{ENV['TRAVIS_RUBY_VERSION']}
    eoh
  else
    ssh_rc = <<-eoh
export GEM_HOME=#{ENV['GEM_HOME']}
export PATH=#{ENV['GEM_HOME']}/bin:$PATH
export RAILS_ENV=production
    eoh
  end
  write_file '.ssh/rc', ssh_rc
end

After('@unicorn_kill') do
  cd ?. do
    pid = File.read("#{@deploy_path}/tmp/run/www.pid").to_i
    Process.kill('QUIT', pid)
  end
end

Before do
  system 'dropdb --if-exists some_host_test > /dev/null'
end
