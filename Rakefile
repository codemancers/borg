require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "borg"
  gem.homepage = "http://github.com/gnufied/borg"
  gem.license = "MIT"
  gem.summary = %Q{A distributed Test Suite runner for Rails, using Eventmachine and Redis}
  gem.description = %Q{A distributed Test Suite runner for Rails, using Eventmachine and Redis}
  gem.email = "hkumar@crri.co.in"
  gem.authors = ["CastleRock"]
end

Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "borg #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
