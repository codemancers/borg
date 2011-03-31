require "fileutils"

module Borg

  class Git
    include Borg::CLI

    attr_accessor :status

    def current_branch
      cmd_output = `git symbolic-ref HEAD`
      branch_name = cmd_output.strip.split("/")[-1]
      branch_name
    end

    def local_branch_ref
      current_head = `git symbolic-ref HEAD`.strip
      `cat .git/#{current_head}`.strip
    end

    def remote_branch_ref
      remote = `git remote`.strip
      `cat .git/refs/remotes/#{remote}/#{current_branch}`.strip
    end

    def update(sha)
      if (local_branch_ref == sha)
        @status = run_in_dir(Rails.root,
                             "#{run_post_reset_hook} && git submodule init && git submodule update && bundle install --local")
      elsif (remote_branch_ref == sha)
        @status = run_in_dir(Rails.root,
                             "git reset --hard #{sha} && #{run_post_reset_hook} && git submodule init && git submodule update && bundle install --local")
      else
        @status = run_in_dir(Rails.root,
                             "git reset --hard HEAD && git fetch && git reset --hard #{sha} && #{run_post_reset_hook} && git submodule init && git submodule update && bundle install --local")
      end
    end

    def run_post_reset_hook
      borg_hook_location = File.join(Rails.root, "borg_post_reset")
      if File.exist?(borg_hook_location)
        "chmod +x #{borg_hook_location} && #{borg_hook_location}"
      else
        ":"
      end
    end

  end
end
