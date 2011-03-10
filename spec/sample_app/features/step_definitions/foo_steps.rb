Given /^I have ingrediants$/ do
  print '.'
  sleep(0.1)
end

When /^I put them in pot$/ do
  print '.'
  sleep 0.1
end

Then /^I should get food$/ do
  print '.'
  sleep 0.1
end

And /^I sleep for (\d+) seconds$/ do |time|
  sleep(time.to_i)
end
