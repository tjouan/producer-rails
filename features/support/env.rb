require 'aruba/cucumber'
require 'producer/core/testing/cucumber'

GEMRC = "gem: --no-ri --no-rdoc\n".freeze

Before('@sshd_gem_env_bundler') do
  env = { 'GEM_HOME' => "#{ENV['HOME']}/.gem" }
  write_file '.gemrc', GEMRC
  write_file '.ssh/rc', <<-eoh
export GEM_HOME=#{env['GEM_HOME']}
export PATH=#{env['GEM_HOME']}/bin:$PATH
  eoh
  with_env(env) do
    unset_bundler_env_vars
    fail unless system 'gem install bundler > /dev/null'
  end
end

Before('@sshd_gem_env') do
  write_file '.gemrc', GEMRC
  write_file '.ssh/rc', <<-eoh
export GEM_HOME=#{ENV['GEM_HOME']}
export PATH=#{ENV['GEM_HOME']}/bin:$PATH
  eoh
end
