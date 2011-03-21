module Borg
  RunHistory = Struct.new(:filename, :running_time)
  class FileSplitter
    attr_accessor :history, :subarrays, :groups

    def initialize(groups)
      @history = []
      @groups = groups
      @subarrays = []
    end

    def prepare_for_splitting
      @history = history.sort {|x,y| y.running_time <=> x.running_time }
      total_sum = sum(history)
      average = total_sum/history.length

      subarray_length = history.length / groups.to_f
      @subarray_sum = average * subarray_length
      groups.times { subarrays << [] }
    end

    def split
      prepare_for_splitting
      min_max_flag = true
      loop do
        groups.times do |i|
          if (min_max_flag)
            if ((x = history.shift) && can_add?(x, subarrays[i]))
              subarrays[i] << x
            else
              @history.unshift(x)
            end
          else
            if ((x = history.pop) && can_add?(x, subarrays[i]))
              subarrays[i] << x
            else
              @history.push(x)
            end
          end
        end
        history.compact!
        min_max_flag = min_max_flag ? false : true
        break if history.empty?
      end
      subarrays
    end

    def can_add?(x, subarray)
      (sum(subarray) < @subarray_sum) || all_subarrays_full?
    end

    def all_subarrays_full?
      flag = true
      subarrays.each do |array|
        if (sum(array) < @subarray_sum)
          flag = false
        end
      end
      flag
    end

    def sum(subarray)
      subarray.inject(0) { |mem, run_history| mem += run_history.running_time }
    end

  end
end
