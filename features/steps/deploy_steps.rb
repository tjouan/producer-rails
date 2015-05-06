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
  in_current_dir do
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
  in_current_dir do
    expect(`git -C #{@deploy_path} log --oneline -1`)
      .to include 'Add generated rails app'
  end
end

Then /^the deployed app repository must be up to date$/ do
  in_current_dir do
    expect(`git -C #{@deploy_path} log --oneline -1`).to include 'Make change'
  end
end

Then /^the deployed app must have its database connection configured$/ do
  check_file_content "#{@deploy_path}/config/database.yml", <<-eoh
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
  check_file_presence "#{@deploy_path}/Gemfile.lock", true
end

Then /^the deployed app must have its database migrations up$/ do
  Bundler.with_clean_env do
    with_env 'RAILS_ENV' => 'production' do
      in_current_dir do
        expect(`cd #{@deploy_path} && bundle exec rake db:migrate:status`)
          .to match /up\s+\d+\s+Create users/
      end
    end
  end
end

Then /^the deployed app must have secret key setup$/ do
  in_current_dir do
    secrets = YAML.load(File.read("#{@deploy_path}/config/secrets.yml"))
    expect(secrets['production']['secret_key_base']).to be
  end
end

Then /^the deployed app must have unicorn configuration$/ do
  check_file_content "#{@deploy_path}/config/unicorn.rb", <<-eoh
worker_processes  2
timeout           60
preload_app       false
pid               'tmp/run/www.pid'
listen            "\#{ENV['HOME']}/#{@deploy_path}/tmp/run/www.sock"
  eoh
end

Then /^the deployed app unicorn server must be running$/ do
  pid_path = "#{@deploy_path}/tmp/run/www.pid"
  check_file_presence pid_path, true
  in_current_dir do
    expect { expect(Process.kill(0, File.read(pid_path).to_i)).to eq 1 }
      .not_to raise_error
  end
end

Then /^the deployed app unicorn server must not be running$/ do
  check_file_presence "#{@deploy_path}/tmp/run/www.pid", false
end

Then /^the deployed app unicorn server must have a different pid$/ do
  in_current_dir do
    expect(File.read("#{@deploy_path}/tmp/run/www.pid").to_i)
      .not_to eq @deploy_unicorn_pid
  end
end
