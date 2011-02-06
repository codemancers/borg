module Borg
  class StartBuild;end

  class StartTest;end

  class StartCucumber; end
  class BuildRequester; end
  
  BuildOutput = Struct.new(:data)
  WorkerConnected = Struct.new(:name)
  BuildStatus = Struct.new(:exit_status)
end

