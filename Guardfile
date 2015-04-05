directories %w[features lib]

guard :cucumber, cli: '--format pretty --quiet', all_on_start: false do
  watch(%r{\Afeatures/.+\.feature\z})
  watch(%r{\Afeatures/support/.+\.rb\z})                { 'features' }
  watch(%r{\Afeatures/step_definitions/.+_steps\.rb\z}) { 'features' }
end
