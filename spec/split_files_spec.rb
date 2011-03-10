require "spec_helper"
require "borg/file_splitter"

describe Borg::FileSplitter do
  describe "Splitting the files based on last running time" do
    before do
      @file_splitter = Borg::FileSplitter.new(3)
      run_array = [1,4,3,2,3,3,6,2,3]
      @sum = run_array.inject(0) {|mem,obj| mem += obj; mem}
      run_array.each_with_index do |num,index|
        @file_splitter.history << Borg::RunHistory.new("file_#{index}",num)
      end
    end
    it "should split the files based on their historic running time" do
      files = @file_splitter.split
      total_sum = 0
      files.each do |group|
        total_sum += @file_splitter.sum(group)
      end
      total_sum.should == @sum
      files.size.should == 3
    end
  end
end
