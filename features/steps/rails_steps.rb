Then /^database migrations for "([^"]+)" must be up$/ do |dir|
  unset_bundler_env_vars
  with_env 'RUBYLIB' => nil, 'RAILS_ENV' => 'production' do
    in_current_dir do
      expect(`cd #{dir} && bundle exec rake db:migrate:status`)
        .to match /up\s+\d+\s+Create users/
    end
  end
end

Then /^secret key for "([^"]+)" must be set$/ do |dir|
  in_current_dir do
    secrets = YAML.load(File.read("#{dir}/config/secrets.yml"))
    expect(secrets['production']['secret_key_base']).to be
  end
end
