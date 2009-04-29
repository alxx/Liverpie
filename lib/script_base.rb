require 'optparse'
require 'ostruct'
require 'pp'
require 'rubygems'

module Liverpie
  class ScriptOptions
    def self.parse(args, process)
      options=OpenStruct.new
      options.daemonize = false
      options.pid_file = "log/liverpie.pid"
      options.cwd = Dir.pwd
      options.action = 'start'
      options.debug = false
      options.verbose = false
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{process} [options]"
        opts.separator  ""
        opts.separator "Specific options:"

        opts.on('-d', '--daemon', 'Run as daemon', 'runs in shell by default') do |ext|
          options.daemonize=true
        end
        opts.on('-p','--pid FILE', 'PID File', 'Defaults to log directory') do |ext|
           options.pid_file = ext
        end
        opts.on('-a', '--action [TYPE]', [:start, :stop], "Action To Do") do |action|
          options.action = action
        end
        opts.on('-C PATH', 'Change dir before starting') do |path|
          options.cwd = path
        end
        opts.on('-v', '--verbose', 'Log communication') do |verbose|
          options.verbose = true
        end
        opts.on('-l', '--list', 'Answer to all events') do |debug|
          options.debug = true
        end
      end

      opts.parse!(args)
      options
    end
  end

  class ScriptHandler
     def initialize(process, &block)
       @process_name = process
       @options=ScriptOptions.parse(ARGV, process)
       @pid_file =File.join(@options.cwd, @options.pid_file)
       if @options.action == 'start'
          self.start &block
       else
         self.stop
        end
     end

     def start    
      log "Starting Server"

       @log_file = File.expand_path(File.join(File.dirname(__FILE__), "../log/liverpie.log"))
        
        log "Logging at #{@log_file}"

        if @options.daemonize
           if File.exists?(@pid_file)
              log "PID File Already Exists!  Exiting..."
              exit
            else
              daemonize
              write_pid_file
            end
         end
        setup_signals

        # require 'commands/servers/base'

        # ActiveRecord::Base.allow_concurrency = true #Prevents connection from dieing... (alxx: what connection?)
        require 'eventmachine'
        
        # tail_thread = tail(Pathname.new(@log_file).cleanpath) unless @options.daemonize # alxx: what's this?
      
       
         begin
            yield @options.verbose, @options.debug
         ensure
          # tail_thread.kill if tail_thread #alxx: hope we don't need this.
           log 'Exiting'
         end
    
 
     end
     def stop
      send_signal("INT", @pid_file)    
     end

     def kill
       log "Exiting..."
       File.unlink(@pid_file) if @pid_file and File.exists?(@pid_file)
      #Need to do this twice as voice_events catches it...
      exit!
     end

     def setup_signals
     # forced shutdown, even if previously restarted (actually just like TERM but for CTRL-C)
         # clean up the pid file always
        at_exit { 
          log "Exiting..."
          File.unlink(@pid_file) if @pid_file and File.exists?(@pid_file) 
          }
      
           trap("INT") { log "INT signal received."; kill}
          if RUBY_PLATFORM !~ /mswin/
            # graceful shutdown
            trap("TERM") { log "TERM signal received."; kill }
            log "Signals ready.  TERM => stop. INT => stop (no restart)."
          end
   
   
     end
     def send_signal(signal, pid_file)
     begin 
       pid = open(pid_file).read.to_i
       print "Sending #{signal} to #{@options.process} at PID #{pid}..."
       Process.kill(signal, pid)
     rescue Errno::ESRCH
       print "Process does not exist.  Not running."
     rescue Errno::ENOENT
        print "No .pid file.  Not shutting down"
      end
  
      puts "Done."
      end
     def log(msg)
 #      STDERR.print "** ", msg, " **\n"
        puts "** #{msg} **"
     end
   
    # Writes the PID file but only if we're on windows.
     def write_pid_file
       log "Write pid"
       log @pid_file
     
       if RUBY_PLATFORM !~ /mswin/
          open(@pid_file,"w") {|f| f.write(Process.pid) }
       end
     end
    def daemonize(options={})
       #ops = resolve_defaults(options)
        # save this for later since daemonize will hose it
        if RUBY_PLATFORM !~ /mswin/
          require 'daemons/daemonize'
          log 'daemonizing!'
          Daemonize.daemonize(@log_file)

          #log File.join(@options.cwd, @options.pid_file)
          # change back to the original starting directory
          Dir.chdir(@options.cwd)
        else
          log "WARNING: Win32 does not support daemon mode."
        end
      end

  end
end