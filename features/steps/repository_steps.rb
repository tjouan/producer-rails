Given /^a rails app repository$/ do
  @repository = 'repos/my_app'
  cd ?. do
    [
      "rails new --database=postgresql --skip-bundle #{@repository} > /dev/null",
      "rm -f #{@repository}/config/secrets.yml",
      "echo gem \\'unicorn\\' >> #{@repository}/Gemfile",
      "cd #{@repository} && bundle install > /dev/null",
      "cd #{@repository} && bundle exec rails g model User name:string > /dev/null 2>&1",
      "rm -f #{@repository}/config/database.yml",
      "echo /config/database.yml > #{@repository}/.gitignore",
      "echo /config/secrets.yml >> #{@repository}/.gitignore",
      "echo /log/*.log >> #{@repository}/.gitignore",
      "echo /public/assets/ >> #{@repository}/.gitignore",
      "echo /tmp/ >> #{@repository}/.gitignore",
      "git -C #{@repository} init > /dev/null",
      "git -C #{@repository} config user.email bob@example",
      "git -C #{@repository} config user.name Bob",
      "git -C #{@repository} add . > /dev/null",
      "git -C #{@repository} commit -m 'Add generated rails app' > /dev/null"
    ].each { |cmd| fail unless Bundler.clean_system(cmd) }
  end
end

Given /^I make a change in the rails app repository$/ do
  cd ?. do
    fail unless system "git -C #{@repository} commit --allow-empty -m 'Make change'"
  end
end
