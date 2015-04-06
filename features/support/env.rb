require 'aruba/cucumber'
require 'producer/core/testing/cucumber'

GEMRC = "gem: --no-ri --no-rdoc\n".freeze

Before('@sshd_gem_env') do
  write_file '.gemrc', GEMRC
  write_file '.ssh/rc', <<-eoh
export GEM_HOME=#{ENV['GEM_HOME']}
export PATH=#{ENV['GEM_HOME']}/bin:$PATH
export RAILS_ENV=production
  eoh
end

After('@unicorn_kill') do
  in_current_dir do
    pid = File.read("#{@deploy_path}/tmp/run/www.pid").to_i
    Process.kill('QUIT', pid)
  end
end

Before do
  system 'dropdb --if-exists some_host_test > /dev/null'
end
