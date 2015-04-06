require 'producer/stdlib'
require 'securerandom'

module Producer
  module Rails
    class << self
      def define_macro(name, &block)
        ::Producer::Core::Recipe.define_macro(name, block)
      end

      def define_test(name, &block)
        ::Producer::Core::Condition.define_test(name, block)
      end
    end

    UNICORN_CONF_PATH     = 'config/unicorn.rb'.freeze
    WWW_PID_PATH          = 'tmp/run/www.pid'.freeze
    WWW_SOCK_PATH         = 'tmp/run/www.sock'.freeze
    BUNDLER_UNSET_GROUPS  = %w[development test].freeze

    define_macro :deploy do |path = get(:app_path)|
      if ENV.key? 'DEPLOY_INIT'
        deploy_init path
      else
        deploy_update path
      end

      assets_update path if set? :assets_update

      deploy_restart
    end

    define_macro :deploy_init do |path = get(:app_path)|
      ensure_dir      path, mode: 0711
      git_clone       get(:repository), path
      app_init        path,
        dirs:   get(:app_mkdir, []),
        files:  get(:app_mkfile, [])
      db_config       path
      bundle_install  path, get(:bundler_unset, [])
      db_init         path
      db_seed         path if set? :db_seed
      secrets_init    path
      www_config      path
    end

    define_macro :deploy_update do |path = get(:app_path)|
      git_update      path
      bundle_install  path
      db_migrate      path
      db_seed         path if set? :db_seed
      www_config      path
    end

    define_macro :deploy_restart do |path = get(:app_path)|
      if ENV.key?('DEPLOY_INIT') || ENV.key?('DEPLOY_START')
        deploy_start path
      else
        deploy_stop path
        deploy_start path
      end
    end

    define_macro :deploy_stop do |path = get(:app_path)|
      www_pid_path  = get :www_pid_path, WWW_PID_PATH
      processes     = get :processes, nil

      app_stop if processes
      www_stop path, www_pid_path
    end

    define_macro :deploy_start do |path = get(:app_path)|
      www_pid_path  = get :www_pid_path, WWW_PID_PATH
      processes     = get :processes, nil

      www_start path, www_pid_path
      app_start path, processes if processes
    end

    define_test :bundle_installed? do |gemfile|
      no_sh "bundle check #{gemfile}"
    end

    define_macro :bundle_install do |path, remove_groups = []|
      gemfile = "--gemfile #{path}/Gemfile"
      without_groups = (remove_groups + BUNDLER_UNSET_GROUPS).join ' '

      condition { bundle_installed? gemfile }

      sh "bundle install --without #{without_groups} #{gemfile}"
    end

    define_macro :app_init do |path, dirs: [], files: {}|
      run_dir = "#{path}/tmp/run"
      dirs << 'public/assets' if set? :assets_update
      dirs.map! { |e| File.join(path, e) }
      files = files.each_with_object({}) do |(k, v), m|
        m[File.join(path, k)] = v
      end

      condition { no_dir? run_dir }

      mkdir run_dir, mode: 0701
      dirs.each   { |e| mkdir e, mode: 0700 }
      files.each  { |k, v| file_write k, v, mode: 0600 }
    end

    define_macro :db_config do |path|
      file_write_once "#{path}/config/database.yml", <<-eoh
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5

production:
  <<: *default
  database: #{target.sub '.', '_'}
      eoh
    end

    define_macro :db_init do |path|
      condition { no_sh 'psql -l | grep -E "^ +%s"' % target }

      sh "cd #{path} && bundle exec rake db:create db:migrate"
    end

    define_macro :db_migrate do |path|
      condition { sh "cd #{path} && bundle exec rake db:migrate:status | grep -E '^ +down'" }

      sh "cd #{path} && bundle exec rake db:migrate"
    end

    define_macro :db_seed do |path|
      sh "cd #{path} && bundle exec rake db:seed"
    end

    define_macro :secrets_init do |path|
      secrets_path = "#{path}/config/secrets.yml"
      conf = <<-eoh
production:
  secret_key_base: #{SecureRandom.hex(64)}
      eoh

      condition { no_file? secrets_path }

      file_write secrets_path, conf
    end

    define_macro :www_config do |path|
      www_config_path = File.join(
        path,
        get(:www_config_path, UNICORN_CONF_PATH)
      )
      conf = <<-eoh
worker_processes  #{get :www_workers}
timeout           #{get :www_timeout, 60}
preload_app       false
pid               '#{get :www_pid_path, WWW_PID_PATH}'
listen            "\#{ENV['HOME']}/#{path}/#{get(:www_sock_path, WWW_SOCK_PATH)}"
      eoh

      condition { no_file_contains www_config_path, conf }

      file_write www_config_path, conf
    end

    define_macro :assets_update do |path|
      sh "cd #{path} && bundle exec rake assets:precompile"
      sh "cd #{path} && chmod 711 public public/assets"
      sh "cd #{path} && find public/assets -type d -exec chmod 711 {} \\;"
      sh "cd #{path} && find public/assets -type f -exec chmod 644 {} \\;"
    end

    define_macro :app_start do |path, processes|
      condition { no_sh 'tmux has-session -t app' }

      sh "cd #{path} && tmux new -d -s app 'foreman start -c #{processes}; zsh'"
    end

    define_macro :app_stop do
      sh 'tmux kill-session -t app'
    end

    define_macro :www_start do |path, www_pid_path|
      condition { no_file? [path, www_pid_path].join('/') }

      sh "cd #{path} && bundle exec unicorn -c config/unicorn.rb -D"
    end

    define_macro :www_reload do |path, www_pid_path|
      sh "kill -HUP $(cat #{path}/#{www_pid_path})"
    end

    define_macro :www_stop do |path, www_pid_path|
      pid_path = [path, www_pid_path].join '/'

      condition { file? pid_path }

      sh "kill -QUIT $(cat #{pid_path}); while [ -f #{pid_path} ]; do sleep 0.1; done"
    end
  end
end
