require "spec_helper"
require "cucumber"
require "borg/borg_git"
include Borg::CLI

describe Borg::CucumberRunner do
  include Helpers

  describe "running the post reset hook" do
    before do
      File.new("#{Rails.root}/borg_post_reset", "w+")
      File.new("#{Rails.root}/config/config.yml.example", "w+")
      File.open("#{Rails.root}/borg_post_reset", "w") do |file|
        file.write("cp config/config.yml.example config/config.yml")
      end
    end

    after do
      File.delete("#{Rails.root}/borg_post_reset") if File.exists?("#{Rails.root}/borg_post_reset")
      File.delete("#{Rails.root}/config/config.yml.example") if File.exists?("#{Rails.root}/config/config.yml.example")
      File.delete("#{Rails.root}/config/config.yml") if File.exists?("#{Rails.root}/config/config.yml")
    end

    it "should copy the config.yml.example to config.yml" do
      run_in_dir Rails.root, Borg::Git.new.run_post_reset_hook
      File.exist?("#{Rails.root}/config/config.yml").should == true
    end

  end
end