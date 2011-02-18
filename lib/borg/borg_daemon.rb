module Borg
  class Daemon
    include AbstractAdapter
    attr_accessor :process_name

    def initialize(process_name)
      @process_name = process_name
    end

    def start(&block)
      if running?
        puts "Borg #{process_name} is already running"
        exit(0)
      elsif(dead?)
        File.delete(pid_file) if File.exists?(pid_file)
      end
      daemonize(&block)
    end

    def stop
      puts "Stopping #{process_name}"
      kill_process
    end

    def pid_file
      "#{Rails.root}/log/#{process_name}.pid"
    end

    def pid
      File.read(pid_file).strip.to_i
    end

    def daemonize(&block)
      if fork                     # Parent exits, child continues.
        sleep(5)
        exit(0)
      else
        Process.setsid
        op = File.open(pid_file, "w")
        op.write(Process.pid().to_s)
        op.close
        redirect_io("#{Rails.root}/log/#{process_name}.log")
        $0 = process_name
        block.call()
      end
    end

    def kill_process
      pgid =  Process.getpgid(pid)
      Process.kill('-TERM', pgid)
      File.delete(pid_file) if File.exists?(pid_file)
      puts "Stopped Borg #{process_name}"
    end

    def process_running?
      begin
        Process.kill(0,self.pid)
        true
      rescue Errno::ESRCH
        false
      end
    end

    def status
      @status ||= begin
                    if pidfile_exists? and process_running?
                      0
                    elsif pidfile_exists? # but not process_running
                      1
                    else
                      3
                    end
                  end

      return @status
    end

    def pidfile_exists?; File.exists?(pid_file); end

    def running?;status == 0;end
    # pidfile exists but process isn't running

    def dead?;status == 1;end
  end
end
