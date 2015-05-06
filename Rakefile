require 'cucumber/rake/task'

task default: :features

Cucumber::Rake::Task.new(:features) do |t|
  t.profile = 'quiet' if ENV.key? 'TRAVIS'
end
