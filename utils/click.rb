require 'socket'

class Click 
  
  def initialize(host="127.0.0.1")
    click_port=7777
    @sock = TCPSocket.new(host, click_port)
    
    #click banner
    line = @sock.gets

  end
  
  
  def ReadHandler(element, handler)
	response=""
	
	@sock.puts "read #{element}.#{handler}\n"

	#click handler OK response
	line = @sock.gets

	line = @sock.gets
	
	if (line.include?("DATA"))
	  bytes = Integer(line.split(" ")[1])
	else
	    $stderr.write("Wrong response from node\n")
	    return "Error in querying click"
	end

	bytesRead=0

	while bytesRead<bytes
	  line = @sock.gets
	  bytesRead = bytesRead + line.size				
	  response="#{response}#{line}"
	end
	
	return response
  end
  
    def WriteHandler(element, handler, msg)
	response=""
	
	@sock.puts "write #{element}.#{handler} #{msg}\n"

	#click handler OK response
	line = @sock.gets
	
	if not (line.include?("OK"))
	    $stderr.write("Wrong response from node\n")
	    return "Error in writehandler click"
	end

  end
  
  def close()
    @sock.close
  end

end