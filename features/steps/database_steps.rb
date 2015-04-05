Given /^database does not exist$/ do
  system 'dropdb some_host_test > /dev/null'
end
