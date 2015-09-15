RECIPE_PATH = 'recipe.rb'.freeze
DEPLOY_PATH = 'deploys/my_app'.freeze

def deploy_recipe_write(repository, macro)
  @deploy_path = DEPLOY_PATH
  write_file RECIPE_PATH, <<-eoh
    require 'producer/rails'

    set :repository,  '#{repository}'
    set :app_path,    '#{@deploy_path}'

    #{macro}
  eoh
end

def deploy_recipe_run(rargv: [])
  run_recipe remote: true, check: true, rargv: rargv, options: '-v'
end

Given /^I write a deployment recipe calling "([^"]+)"$/ do |macro|
  deploy_recipe_write @repository, macro
end

Given /^I write a standard deployment recipe$/ do
  deploy_recipe_write @repository, 'deploy'
end

Given /^I make the initial deployment$/ do
  deploy_recipe_write @repository, 'deploy_init'
  deploy_recipe_run
end

Given /^I start the deployed app$/ do
  deploy_recipe_write @repository, 'deploy_start'
  deploy_recipe_run
end

Given /^the deployed app unicorn server is running with a certain pid$/ do
  cd ?. do
    @deploy_unicorn_pid = File.read("#{@deploy_path}/tmp/run/www.pid").to_i
  end
end

When /^I execute the deployment recipe$/ do
  deploy_recipe_run
end

When /^I execute the deployment recipe with "([^"]+)" recipe argument$/ do |arg|
  deploy_recipe_run rargv: [arg]
end

Then /^the deployed app must be initialized$/ do
  step 'the deployed app must have unicorn configuration'
end

Then /^the deployed app repository must be cloned$/ do
  cd ?. do
    expect(`git -C #{@deploy_path} log --oneline -1`)
      .to include 'Add generated rails app'
  end
end

Then /^the deployed app repository must be up to date$/ do
  cd ?. do
    expect(`git -C #{@deploy_path} log --oneline -1`).to include 'Make change'
  end
end

Then /^the deployed app must have its database connection configured$/ do
  expect("#{@deploy_path}/config/database.yml").to have_file_content <<-eoh
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5

production:
  <<: *default
  database: some_host_test
  eoh
end

Then /^the deployed app must have its dependencies installed$/ do
  expect("#{@deploy_path}/Gemfile.lock").to be_an_existing_file
end

Then /^the deployed app must have its database migrations up$/ do
  Bundler.with_clean_env do
    with_environment 'RAILS_ENV' => 'production' do
      cd ?. do
        expect(`cd #{@deploy_path} && bundle exec rake db:migrate:status`)
          .to match /up\s+\d+\s+Create users/
      end
    end
  end
end

Then /^the deployed app must have secret key setup$/ do
  cd ?. do
    secrets = YAML.load(File.read("#{@deploy_path}/config/secrets.yml"))
    expect(secrets['production']['secret_key_base']).to be
  end
end

Then /^the deployed app must have unicorn configuration$/ do
  expect("#{@deploy_path}/config/unicorn.rb").to have_file_content <<-eoh
worker_processes  2
timeout           60
preload_app       false
pid               'tmp/run/www.pid'
listen            "\#{ENV['HOME']}/#{@deploy_path}/tmp/run/www.sock"
  eoh
end

Then /^the deployed app unicorn server must be running$/ do
  pid_path = "#{@deploy_path}/tmp/run/www.pid"
  expect(pid_path).to be_an_existing_file
  cd ?. do
    expect { expect(Process.kill(0, File.read(pid_path).to_i)).to eq 1 }
      .not_to raise_error
  end
end

Then /^the deployed app unicorn server must not be running$/ do
  expect("#{@deploy_path}/tmp/run/www.pid").not_to be_an_existing_file
end

Then /^the deployed app unicorn server must have a different pid$/ do
  cd ?. do
    expect(File.read("#{@deploy_path}/tmp/run/www.pid").to_i)
      .not_to eq @deploy_unicorn_pid
  end
end
