Given /^I make the initial deployment$/ do
  write_file 'recipe.rb', <<-eoh
    require 'producer/rails'

    set :repository,  '#{@repository}'
    set :app_path,    'deploys/my_app'
    set :www_workers, 2

    deploy_init
  eoh
  run_recipe remote: true, check: true
end

Then /^the deployed app repository must be up to date$/ do
  in_current_dir do
    expect(`git -C deploys/my_app log --oneline -1`).to include 'Make change'
  end
end
