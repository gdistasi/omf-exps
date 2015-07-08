require 'core/orbit.rb'

class AodvHelper # * AODV * #
  @@defined=false

  def initialize(interfaces, orbit, logtime=3)
    
    @interfaces=interfaces
    
    @logtime=logtime
    @orbit=orbit

    @name="aodvApplication"
    #@path="/usr/local/bin/aodvd -l -d 2>&1 > /tmp/aodv.log"
    #@path="/usr/local/bin/aodvd"
    @path="/usr/local/bin/aodvd -r 3 -l -d"
    #@path="/usr/local/bin/aodvd -l /tmp/aodv.log"
    #@path="/usr/local/bin/aodvd 2>&1 > /tmp/aodv.log"
    defProperty('reputationEnabled', 'no', "Set to yes to enable reputation extensions")  

    
    if (@@defined==false)
      self.DefineApp
      @@defined=true
    end
  end
  
  def Install(node_id)
  
    group("node#{node_id}").addApplication(@name, :id => @name ) do |app|
#	  app.setProperty('id', node_id)

	  interfaces=""
	  @interfaces.each do |int|
	      interfaces="#{interfaces}#{int.name},"
	  end
	  interfaces.chomp!(",")

	  app.setProperty('interface', interfaces)
	  # app.setProperty('log-rt-table', @logtime)
	  
	  puts "Adding AodvStack on node #{node_id}"
   end  
   
      return Orbit::Application.new(node_id, @name)
  end
  
  def DefineApp
   
    defApplication('aodvApplication', 'aodv') do |app|
  
      app.path = @path  
      app.version(1, 1, 1)
      app.shortDescription = "Aodv-uu(+rex)" 
      app.description = "Aodv routing layer with optionally non-repudiation " 
      
      if (@orbit.GetEnv=="ORBIT")
	 envFlag="Orbit"
      elsif (@orbit.GetEnv=="MYXEN")
	envFlag="Xen"
      else
	 $stderr.puts("Environment not supported by AODV!")
	 exit(1)
      end
      
      if (@orbit.ECCanServeFiles())    
	extraUrl="."
      else
	extraUrl="http://#{@orbit.GetECAddress()}:8000"
      end
      
      if (property.reputationEnabled.to_s=="no")
          app.appPackage = "#{extraUrl}/bin/aodv-uu-#{envFlag}.tar.gz"
      else
          app.appPackage = "#{extraUrl}/bin/aodv-#{envFlag}.tar.gz"
      end
	
#      app.defProperty('id', 'Node id', nil, 
#		    {:type => :integer, :dynamic => false})
      app.defProperty('interface', "Interfaces used", "-i",
                     {:type => :string, :dynamic => false})
      # app.defProperty('log-rt-table', "Set the refresh time of logging the rt-table", nil, {:type => :integer, :dynamic => false})
    end
    
    #kill any left instance on the nodes
    # allGroups.exec("killall aodvd >/dev/null 2>&1; /bin/true")
  end
end
