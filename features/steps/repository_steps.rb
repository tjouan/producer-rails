Given /^a rails app repository$/ do
  @repository = 'repos/my_app'
  in_current_dir do
    [
      "rails new --database=postgresql --skip-bundle #{@repository} > /dev/null",
      "rm -f #{@repository}/config/secrets.yml",
      "BUNDLE_GEMFILE=#{@repository}/Gemfile bundle install > /dev/null",
      "cd #{@repository} && BUNDLE_GEMFILE=Gemfile bundle exec rails g model User name:string > /dev/null 2>&1",
      "git -C #{@repository} init > /dev/null",
      "git -C #{@repository} config user.email bob@example",
      "git -C #{@repository} config user.name Bob",
      "git -C #{@repository} add . > /dev/null",
      "git -C #{@repository} commit -m 'Add generated rails app' > /dev/null"
    ].each { |cmd| fail unless system cmd }
  end
end

Given /^I make a change in the rails app repository$/ do
  in_current_dir do
    fail unless system "git -C #{@repository} commit --allow-empty -m 'Make change'"
  end
end
