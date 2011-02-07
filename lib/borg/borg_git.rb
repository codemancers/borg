require "fileutils"

module Borg

  class Git
    attr_accessor :status
    def current_branch
      cmd_output = `git symbolic-ref HEAD`
      branch_name = cmd_output.strip.split("/")[-1]
      branch_name
    end

    def update(worker)
      FileUtils.cd(Rails.root) do
        #update_command = "git reset --hard HEAD && git fetch && git rebase origin/#{current_branch} && git submodule init && git submodule update && bundle install --local"

        update_command = "ls"
        puts "Update command is #{update_command}"
        EM.popen(update_command,TestRunner) do |process|
          process.worker = worker
          process.runner_type = 'git'
        end

      end

    end

  end
end
