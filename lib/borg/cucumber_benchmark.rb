require "cucumber/formatter/progress"

module Borg
  class Benchmark < Cucumber::Formatter::Progress
    include Borg::AbstractAdapter

    def before_feature(feature)
      @start_time = Time.now
    end

    def after_feature(feature)
      time_taken = Time.now - @start_time
      puts "Feature #{feature.file} took #{time_taken} seconds to run"
      redis[feature.file] = time_taken
    end
  end
end

