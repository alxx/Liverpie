require 'net/http'

class LiverpieClient

  def initialize
    webapps = Liverpie.webapps
    @webapp_connections = {}
    webapps.keys.each do |webapp_id| 
      @webapp_connections[webapp_id] = { 
                      :http => Net::HTTP.new(webapps[webapp_id]['ip'], webapps[webapp_id]['port']),
                      :state_machine_uri => webapps[webapp_id]['state_machine_uri'],
                      :dtmf_uri => webapps[webapp_id]['dtmf_uri'],
                      :reset_uri => webapps[webapp_id]['reset_uri']
                     }
    end
  end
  
  # Send a regular event triggered by the webapp. This is the state machine call.
  def send(params, cookie)
    requested_webapp_id = params['variable_liverpie_webapp_id']
    Liverpie.log "Calling webapp #{requested_webapp_id}..."
    
    hdrs = {}
    hdrs['Cookie'] = cookie if cookie
    
    webapp_connection = get_webapp_connection(requested_webapp_id)
    return [nil, nil] unless webapp_connection
    
    partxt = params.keys.map { |k| "#{k}=#{params[k]}"}*'&'
    
    begin
      resp = webapp_connection[:http].post(webapp_connection[:state_machine_uri], partxt, hdrs)
    rescue Exception => e
      Liverpie.log "Error - could not reach the webapp: #{e.message}"
      return [nil, nil]
    end
    
    case resp.code.to_i
    when 200, 302
      received_cookie = resp['Set-Cookie']
      Liverpie.log "Got webapp response for runner method"
    else
      Liverpie.log "Error - code(#{resp.code}) - #{resp.msg}"
    end
    
    return [(resp.code.to_i == 200 ? resp.body : nil), received_cookie.to_s.empty? ? cookie : received_cookie]
  end
  
  # Asynchronously notify the webapp of all the inbound DTMF codes.
  def send_dtmf(code, cookie, requested_webapp_id)
    Liverpie.log "Sending DTMF #{code} to webapp #{requested_webapp_id}..."
    
    webapp_connection = get_webapp_connection(requested_webapp_id)
    return nil, cookie unless webapp_connection
    
    # If this wasn't configured, then ignore DTMF
    return nil, cookie if webapp_connection[:dtmf_uri].to_s.empty?
        
    hdrs = {}
    hdrs['Cookie'] = cookie if cookie
    
    begin
      resp = webapp_connection[:http].post(webapp_connection[:dtmf_uri], "dtmf_code=#{code}", hdrs)
    rescue Exception => e
      Liverpie.log "Error - could not reach the webapp: #{e.message}"
      return [nil, nil]
    end
    
    case resp.code.to_i
    when 200, 302
      received_cookie = resp['Set-Cookie']
      Liverpie.log "Got webapp response for dtmf method"
    else
      Liverpie.log "Error - code(#{resp.code}) - #{resp.msg}"
    end
    
    return [(resp.code.to_i == 200 ? resp.body : nil), received_cookie.to_s.empty? ? cookie : received_cookie]
  end
  
  # Reset the webapp state machine
  def reset(requested_webapp_id)
    Liverpie.log "Resetting state machine in webapp #{requested_webapp_id}..."
    
    webapp_connection = get_webapp_connection(requested_webapp_id)
    return nil unless webapp_connection
    
    begin
      resp = webapp_connection[:http].get(webapp_connection[:reset_uri])    
    rescue Exception => e
      Liverpie.log "Error - could not reach the webapp: #{e.message}"
      return nil
    end
    
    case resp.code.to_i
    when 200, 302
      received_cookie = resp['Set-Cookie']
      Liverpie.log "Got webapp response for reset method"
    else
      Liverpie.log "Error - code(#{resp.code}) - #{resp.msg}"
    end
    return received_cookie
  end
  
  private
  
  # Find out what webapp do we need to talk to
  def get_webapp_connection(requested_webapp_id)
    if requested_webapp_id.to_s.empty?
      Liverpie.log "Error - Freeswitch didn't send us a liverpie_webapp_id, check that you set liverpie_webapp_id in your dialplan before calling Liverpie"
      return false
    end
    
    webapp_connection = @webapp_connections[requested_webapp_id]
    
    if webapp_connection.nil?
      Liverpie.log "Error - No webapp named #{requested_webapp_id} is configured in liverpie.conf"
      return false
    end
    
    webapp_connection
  end
  
end