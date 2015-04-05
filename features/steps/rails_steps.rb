Given /^a rails app repository in remote directory "([^"]+)"$/ do |dir|
  in_current_dir do
    [
      "rails new --database=postgresql --skip-bundle #{dir} > /dev/null",
      "git -C #{dir} init > /dev/null",
      "git -C #{dir} config user.email bob@example",
      "git -C #{dir} config user.name Bob",
      "git -C #{dir} add . > /dev/null",
      "git -C #{dir} commit -m 'Add generated rails app' > /dev/null"
    ].each { |cmd| fail unless system cmd }
  end
end
