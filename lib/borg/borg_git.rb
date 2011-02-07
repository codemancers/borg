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
        @status = system("git reset --hard HEAD && git fetch && git rebase origin/#{current_branch} && git submodule init && git submodule update && bundle install --local")
      end
    end

  end
end
