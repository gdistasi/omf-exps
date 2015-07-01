require './orbit.rb'

class AodvHelper # * AODV * #
  
  @@defined=false

  def initialize(interface, orbit, logtime=3)
    @interfaces=Array.new
    @interfaces<<interface

    @logtime=logtime

    @name="aodv"
    @path="aodv.sh -l -r 3 -d"
    #@path="aodvd -l -d 2>&1 > /tmp/aodv.log"
    #@path="/usr/local/bin/aodvd -l -d"
    #@path="/usr/local/bin/aodvd -l /tmp/aodv.log"
    #@path="/usr/local/bin/aodvd 2>&1 > /tmp/aodv.log"

    defProperty('aodvRepOn', 'no', "set to yes enable kernel mode")

    
    if (@@defined==false)
      self.DefineApp
      @@defined=true
    end
    

  end
  
  def Install(node_id)
  
    @name="aodvApplication"
  
    group("node#{node_id}").addApplication(@name, :id => @name ) do |app|
#	  app.setProperty('id', node_id)
	  
	  inter_names=Array.new
	  @interfaces.each do |int|
	    inter_names << int.name
	  end

	  interfaces=""
	  @interfaces.each do |int|
	      interfaces="#{interfaces}#{int.name}"
	  end
	  interfaces.chomp!(",")

          logtime=@logtime
	  
	  app.setProperty('interface', interfaces)
	  #app.setProperty('log-rt-table', logtime)
	  
	  puts "Adding AodvStack on node #{node_id}"
   end  
   
      return Orbit::Application.new(node_id, @name)
  end
  
  def DefineApp
   
    defApplication('aodvApplication', 'aodv') do |app|
  
      app.path = @path  
      app.version(1, 1, 1)
      app.shortDescription = "Aodv-uu" 
      app.description = "Aodv routing layer" 
      
      if (property.aodvRepOn.tos!="no")
	if (property.env.tos=="ORBIT")
	  app.appPackage = "bin/aodv-uu-Orbit.tar.gz"
	else
	  app.appPackage = "bin/aodv-uu-Xen.tar.gz"
	end
      else
	if (property.env.tos=="ORBIT")
  	  app.appPackage = "bin/aodv-Orbit.tar.gz"
	else
	  app.appPackage = "bin/aodv-Xen.tar.gz"
	end
      end
#      app.defProperty('id', 'Node id', "--id", 
#		    {:type => :integer, :dynamic => false})
      app.defProperty('interface', "Interface used", "--interface",
                     {:type => :string, :dynamic => false})
      # app.defProperty('log-rt-table', "Set the refresh time of logging the rt-table", nil, {:type => :integer, :dynamic => false})
    end
    
    #kill any left instance on the nodes
    allGroups.exec("killall aodvd >/dev/null 2>&1; /bin/true")
  end
end
