require 'eventmachine'

module LiverpieServer
  def post_init
    Liverpie.log "New Connection"
    @receive_buffer = ''
    @connection_params = nil
    @initial_commands = []
    #@initial_commands << "log DEBUG\n\n"
    @initial_commands << "myevents\n\n"

    @initialized = false
    @latest_variables = {}
    @cookie = nil
    @client = LiverpieClient.new
    @expected_key = 'content_type'
    @expected_value = 'command/reply'
    
    send "connect"
  end
 
  def set_modes(verbose, debug)
    Liverpie.log "Turning on Debug Mode" if @debug = debug
    Liverpie.log "Turning on Verbose Mode" if @verbose = verbose
  end
  
  def receive_data data
    @receive_buffer << data
          
    # Act for data that ends in two newlines
    if @receive_buffer[-2..-1] == "\n\n"
      @params = hashify @receive_buffer
      @receive_buffer = ''
      
      Liverpie.log "Data Received (content-type: #{@params['content_type']}):\n#{data}" if @verbose

      # First we run the initial commands.
      unless @initialized
        
        Liverpie.log "Initializing connection..."

        @connection_params ||= @params
        cmd = @initial_commands.shift
        if cmd.is_a?(Hash)
          send_application cmd[:app], cmd[:params]
        else
          send cmd
        end
        @initialized = @initial_commands.empty?
        @latest_variables.merge!(@params)

        # Start the state machine also
        @cookie = @client.reset(@params['variable_liverpie_webapp_id']) if @initialized
      else   

        content_types = [@latest_variables['content_type'], @params['content_type']]
        if content_types - [ 'text/event-plain' ] != content_types # only merge we got one of those content_types
          @latest_variables.merge!(@params)
        end

        Liverpie.log "Waiting for params[#{@expected_key}] to be #{@expected_value}." if @verbose
        if @params[@expected_key] == @expected_value          
          resp, @cookie = @client.send(@latest_variables, @cookie)
          if resp.to_s.empty?
            Liverpie.log "PROBLEM: Didn't get any response from webapp"
          else
            yaml = YAML.load(resp)
            @expected_key, @expected_value = yaml['expected_key'], yaml['expected_value']
            send yaml['msg']
          end
        end
        
        # Liverpie.log "N Param keys: #{hashify(data).keys.inspect}"
        
        # If we find an inband DTMF code, always send it to the webapp.
        # In this case, the webapp may return an empty response, or an YAML. We don't do anything in the first case.
        if @params['dtmf_digit']
          resp, @cookie = @client.send_dtmf(@params['dtmf_digit'], @cookie, @latest_variables['variable_liverpie_webapp_id'])
          yaml = YAML.load(resp)
          msg  = yaml ? yaml['msg'].nil? ? nil : yaml['msg'] : nil
          send msg if msg
        end
        
        @started = true unless @started
 
      end # unless initialized
    end # data ends
  end

  def unbind
    puts "Disconnected from Freeswitch"
  end
 
  def hashify data
    hsh = Hash.new
    data.split("\n").each do |line|
      hsh[line.split(':')[0].strip.gsub('-', '_').downcase] = line.split(':')[1].strip unless line.empty?
    end
    hsh
  end

  def send_application app, params=nil
    msg = "SendMsg #{@connection_params['unique-id'].to_s}\ncall-command: execute\nexecute-app-name: #{app}"
    msg << "\nexecute-app-arg: #{params}" #if params
    send msg
  end

  def send data
    Liverpie.log "Sending:\n#{data}" if @verbose
    send_data data + "\n\n"
   end
end