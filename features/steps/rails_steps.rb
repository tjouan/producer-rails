Given /^a rails app repository in remote directory "([^"]+)"$/ do |dir|
  in_current_dir do
    [
      "rails new --skip-bundle #{dir} > /dev/null",
      "git -C #{dir} init > /dev/null",
      "git -C #{dir} add . > /dev/null",
      "git -C #{dir} commit -m 'Add generated rails app' > /dev/null"
    ].each { |cmd| fail unless system cmd }
  end
end
