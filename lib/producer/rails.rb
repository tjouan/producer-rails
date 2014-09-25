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

    define_macro :deploy do
      app_path = get :app_path
      $app_path = app_path

      if ENV.key? 'DEPLOY_INIT'
        ensure_dir      app_path, 0701
        git_clone       get(:repository), app_path
        app_init        app_path, get(:app_mkdir)
        bundle_install  app_path
        db_config       app_path
        db_init         app_path
        secrets_init    app_path
        www_config      app_path
      else
        git_update      app_path
        bundle_install  app_path
        db_migrate      app_path
      end

      assets_update app_path


      www_pid_path  = get :www_pid_path
      queue_workers = get :queue_workers

      if ENV.key? 'DEPLOY_INIT'
        www_start app_path, www_pid_path
        app_start app_path, queue_workers
      else
        app_stop
        www_stop  app_path, www_pid_path
        www_start app_path, www_pid_path
        app_start app_path, queue_workers
      end
    end

    define_test :bundle_installed? do |gemfile|
      no_sh "bundle check #{gemfile}"
    end

    define_macro :bundle_install do |path|
      gemfile = "--gemfile #{path}/Gemfile"

      condition { bundle_installed? gemfile }

      sh "bundle install --without development test #{gemfile}"
    end

    define_macro :app_init do |path, dirs: []|
      directories = (%w[tmp tmp/run] + dirs).map do |e|
        File.join(path, e)
      end

      condition { no_dir? directories.first }

      directories.each { |e| mkdir e, 0700 }
      sh "cd #{path} && chmod 701 tmp tmp/run"
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
      www_config_path = File.join(path, get(:www_config_path))
      conf = <<-eoh
worker_processes  #{get :www_workers}
preload_app       false
pid               '#{get :www_pid_path}'
listen            "\#{ENV['HOME']}/#{path}/#{get :www_sock_path}"
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
