Given /^a rails app repository in remote directory "([^"]+)"$/ do |dir|
  in_current_dir do
    [
      "rails new --database=postgresql --skip-bundle #{dir} > /dev/null",
      "rm -f #{dir}/config/secrets.yml",
      "BUNDLE_GEMFILE=#{dir}/Gemfile bundle install > /dev/null",
      "cd #{dir} && BUNDLE_GEMFILE=Gemfile bundle exec rails g model User name:string > /dev/null 2>&1",
      "git -C #{dir} init > /dev/null",
      "git -C #{dir} config user.email bob@example",
      "git -C #{dir} config user.name Bob",
      "git -C #{dir} add . > /dev/null",
      "git -C #{dir} commit -m 'Add generated rails app' > /dev/null"
    ].each { |cmd| fail unless system cmd }
  end
end

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
