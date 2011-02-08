module Borg
  class StartBuild;end

  class StartTest;end

  class StartCucumber; end
  
  BuildOutput = Struct.new(:data)
  WorkerConnected = Struct.new(:name)
  BuildStatus = Struct.new(:exit_status)
  BuildRequester = Struct.new(:sha)
  StartBuild = Struct.new(:sha)
end

