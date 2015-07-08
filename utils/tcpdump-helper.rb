require 'core/orbit.rb'
require 'core/helper.rb'

class TcpdumpHelper < Helper
  
	def Install(node_id, interface)
	     name="tcpdumpapplication-#{interface}"
	     group("node#{node_id}").addApplication('tcpdumpapplication', :id => name ) do |app|
		app.setProperty("logfile", "/tmp/tcpdump-#{node_id}-#{interface}.pcap")
		app.setProperty("interface", "#{interface}")
	     end
	  
	  
	  puts "Adding TcpDump on node #{node_id} and interface #{interface}"
	  
	  return Orbit::Application.new(node_id, name)
	end
	  
	private
	
	def DefineApp
  
	  defApplication('tcpdumpapplication','tcpdump') do |app|
	    
	    app.path = "/usr/sbin/tcpdump"
	    app.version(1,1,1)
	    app.shortDescription = "Tcpdump app" 
	    app.defProperty("interface", "Interface to listen on.",
	                    "-i", {:type => :string, :dynamic => false})
	    app.defProperty("logfile", "Name of the log file.",
	                    "-w", {:type => :string, :dynamic => false})    
	  end
	  
	end


end
