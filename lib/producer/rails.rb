module Producer
  module Rails
    require 'producer/stdlib'
    require 'securerandom'

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
    WWW_SOCK_PATH         = 'tmp/run/www.socke'.freeze
    BUNDLER_UNSET_GROUPS  = %w[development test].freeze

    define_macro :deploy do
      app_path = get :app_path

      if ENV.key? 'DEPLOY_INIT'
        deploy_init app_path
      else
        deploy_update app_path
      end

      assets_update app_path

      www_pid_path  = (get :www_pid_path rescue WWW_PID_PATH)
      queue_workers = (get :queue_workers rescue nil)

      deploy_restart
    end

    define_macro :deploy_init do |app_path = get(:app_path)|
      app_path ||= get :app_path

      ensure_dir      app_path, mode: 0701
      git_clone       get(:repository), app_path
      app_init        app_path,
        dirs:   (get :app_mkdir rescue []),
        files:  (get :app_mkfile rescue [])
      db_config       app_path
      bundle_install  app_path, (get :bundler_unset rescue [])
      db_init         app_path
      secrets_init    app_path
      www_config      app_path
    end

    define_macro :deploy_update do |app_path = nil|
      app_path ||= get :app_path

      git_update      app_path
      bundle_install  app_path
      db_migrate      app_path
      db_seed         app_path if (get :db_seed rescue false)
    end

    define_macro :deploy_restart do |app_path = nil|
      app_path ||= get :app_path

      if ENV.key?('DEPLOY_INIT') || ENV.key?('DEPLOY_START')
        deploy_start
      else
        deploy_stop
        deploy_start
      end
    end

    define_macro :deploy_stop do
      app_path      ||= get :app_path
      www_pid_path  = (get :www_pid_path rescue WWW_PID_PATH)
      queue_workers = (get :queue_workers rescue nil)

      app_stop if queue_workers
      www_stop app_path, www_pid_path
    end

    define_macro :deploy_start do
      app_path      ||= get :app_path
      www_pid_path  = (get :www_pid_path rescue WWW_PID_PATH)
      queue_workers = (get :queue_workers rescue nil)

      www_start app_path, www_pid_path
      app_start app_path, queue_workers if queue_workers
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
      dirs << 'public/assets'
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
      path = "#{path}/config/database.yml"
      conf = <<-eoh
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5

production:
  <<: *default
  database: #{target}
          eoh

      condition { no_file? path }

      file_write path, conf
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
      path = "#{path}/config/secrets.yml"
      conf = <<-eoh
production:
  secret_key_base: #{SecureRandom.hex(64)}
      eoh

      condition { no_file? path }

      file_write path, conf
    end

    define_macro :www_config do |path|
      www_config_path = File.join(
        path,
        (get :www_config_path rescue UNICORN_CONF_PATH)
      )
      conf = <<-eoh
worker_processes  #{get :www_workers}
preload_app       false
pid               '#{get :www_pid_path}'
listen            "\#{ENV['HOME']}/#{path}/#{(get :www_sock_path rescue WWW_SOCK_PATH)}"
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

    define_macro :app_start do |app_path, queue_workers|
      condition { no_sh 'tmux has-session -t app' }

      sh "cd #{app_path} && tmux new -d -s app 'foreman start -c queue=1,worker=#{queue_workers}; zsh'"
    end

    define_macro :app_stop do
      sh 'tmux kill-session -t app'
    end

    define_macro :www_start do |app_path, www_pid_path|
      condition { no_file? [app_path, www_pid_path].join('/') }

      sh "cd #{app_path} && bundle exec unicorn -c config/unicorn.rb -D"
    end

    define_macro :www_reload do |app_path, www_pid_path|
      sh "kill -HUP $(cat #{app_path}/#{www_pid_path})"
    end

    define_macro :www_stop do |app_path, www_pid_path|
      condition { file? [app_path, www_pid_path].join('/') }

      sh "kill -QUIT $(cat #{app_path}/#{www_pid_path}); sleep 1"
    end
  end
end
