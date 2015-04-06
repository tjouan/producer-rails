RECIPE_PATH = 'recipe.rb'.freeze

def deploy_recipe_write(repository, macro)
  write_file RECIPE_PATH, <<-eoh
    require 'producer/rails'

    set :repository,  '#{repository}'
    set :app_path,    'deploys/my_app'
    set :www_workers, 2

    #{macro}
  eoh
end

def deploy_recipe_run
  run_recipe remote: true, check: true
end

Given /^I write a deployment recipe calling "([^"]+)"$/ do |macro|
  deploy_recipe_write @repository, macro
end

Given /^I make the initial deployment$/ do
  deploy_recipe_write @repository, 'deploy_init'
  deploy_recipe_run
end

Then /^the deployed app repository must be up to date$/ do
  in_current_dir do
    expect(`git -C deploys/my_app log --oneline -1`).to include 'Make change'
  end
end
