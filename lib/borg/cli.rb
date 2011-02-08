require "fileutils"

module Borg
  module CLI
    def run_clean(command)
      status = nil
      Bundler.with_clean_env do
        status = system(command)
      end
      status
    end

    def run_in_dir(dir,command)
      status = nil
      FileUtils.cd(dir) do
        status = run_clean(command)
      end
      status
    end
  end
end
