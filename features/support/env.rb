require 'aruba/cucumber'
require 'producer/core/testing/cucumber'

Before('@ruby_bundler') do
  env = { 'GEM_HOME' => "#{ENV['HOME']}/.gem" }
  write_file '.gemrc', "gem: --no-ri --no-rdoc\n"
  write_file '.ssh/rc', <<-eoh
export GEM_HOME=#{env['GEM_HOME']}
export PATH=#{env['GEM_HOME']}/bin:$PATH
    eoh
  with_env(env) do
    unset_bundler_env_vars
    fail unless system 'gem install bundler > /dev/null'
  end
end
