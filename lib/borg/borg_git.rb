require "fileutils"

module Borg

  class Git
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
      if(local_branch_ref == sha)
        @status = true
      elsif(remote_branch_ref == local_branch_ref)
        @status = true
      else
        FileUtils.cd(Rails.root) do
          @status = system("git reset --hard HEAD && git fetch && git reset --hard #{sha} && git submodule init && git submodule update")
        end
      end
    end

  end
end
