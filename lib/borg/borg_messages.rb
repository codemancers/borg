module Borg
  class StartTest;end
  class StartCucumber; end
  
  BuildOutput = Struct.new(:data)
  WorkerConnected = Struct.new(:name, :options)
  BuildStatus = Struct.new(:exit_status)
  BuildRequester = Struct.new(:sha)
  StartBuild = Struct.new(:sha)

  WorkerData = Struct.new(:worker, :worker_options)
end

