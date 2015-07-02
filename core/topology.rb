require 'utils/utils.rb'
require 'node.rb'

class Orbit

# describe an experimental topology  
  
class Topology

	attr_accessor :nodes, :senders, :receivers, :links, :wired_links, :endHosts

	def initialize(topo, orbit=nil, dontcreate=false)
		@nodes=Array.new
		@links=Array.new
		@wired_links=Array.new
		@killedLinks=Array.new	
		@senders=Array.new
		@receivers=Array.new
		@endHosts=Array.new
		@rate=6
		@orbit=orbit
		@dontcreate=dontcreate
		@topoFile=topo
		
		ReadTopo(topo)
		CreateVarFile()
	end

	#adding links based on the desired transmission range
	def AddLinksInRange(range)
		puts("Adding links in range")
		@nodes.each do |x|
	    		@nodes.each do |y|
		  		if (x.id!=y.id and Distance(x,y)<=range)
		      			puts("Adding link between node #{x.id} and node #{y.id}")
					@links << Link.new(x,y, @rate)
		  		end	
			end
		end      

	end
	
	def SetRate(rate)
	  @rate=rate
	end

	#return the set of links which are not been defined
	def LinksToRemove
		
		#removing unwanted links
		@nodes.each do |nodeA|
			@nodes.each do |nodeB|

				if nodeA==nodeB
					next
				end

				tempLink=Link.new(nodeA,nodeB)
				revTempLink=Link.new(nodeB,nodeA)

				#check if this link has been requested
		      		reqLink=false        
		      		@links.each do |link|
			  		if Equals(tempLink, link)
			      			reqLink=true
			  		end
		      		end
		      
		      		if not reqLink and (nodeA.type=="R" and nodeB.type=="R")
					puts("Removing link between node #{nodeA.id} and #{nodeB.id}\n")
					@killedLinks << tempLink
		      		end


			end
		end 

		return @killedLinks

	end

	#add the links specified in a config file
	#Each line of the file has the following format: L idNode1 idNode2 rate
  	def AddLinksFromFile(linkfile)		
		file=File.new(linkfile, "r")
		# reading nodes information
    
		while (line = file.gets)
      			line.chomp!("\n")
      			
			if (line.size==0 or line.strip[0].chr=='#')
				next
      			end

	
		     	a=line.split(" ")
      			
			if a.size > 0
			    if a[0] == "L"
			      link = Link.new(@nodes[Integer(a[1])], @nodes[Integer(a[2])], Integer(a[3]) )
			      revLink = Link.new(@nodes[Integer(a[2])], @nodes[Integer(a[1])], Integer(a[3]) )
			      puts("Adding link between node #{a[1]} and node #{a[2]}")
      			      puts("Adding link between node #{a[2]} and node #{a[1]}")
			      @links << link
			      @links << revLink
			    elsif a[0] == "WL"
			      if @nodes[Integer(a[2])].type=="R"
			        link = Link.new(@nodes[Integer(a[1])], @nodes[Integer(a[2])], @nodes[Integer(a[3])] )
				puts("Adding wired link between node #{a[1]} and node #{a[2]}")
				@wired_links << link
			      else
			        link = Link.new(@nodes[Integer(a[2])], @nodes[Integer(a[1])], @nodes[Integer(a[3])] )
				puts("Adding wired link between node #{a[2]} and node #{a[1]}")
				@wired_links << link
			      end

			    else
			      $stderr.puts("Wrong link type: #{a[0]}")
			    end
			end
		end
	
		file.close

		@linksFile=linkfile
	end
	
	#write a file which contains the list of links defined for this topology
	def CreateLinkFile(linkfile)
	  file=File.open(linkfile, "w")

	  @links.each do |link|

	      file.write("L #{link.from.id} #{link.to.id} #{@rate}\n")
	    
	  end
	  
	  file.close

	end

	
  def include?(x,y)
    inc=false
    @nodes.each do |node|
	if node.x==x and node.y==y
	    inc=true
	    break
	end
    end
    return inc
  end
	
  #create the topo file to be used with omf to load images on nodes
  def CreateTopoFile
    topo52="topo52"
    topo53="topo53"
    
    if File.exists?(topo53)
      File.delete(topo53)
    end
    if File.exists?(topo52)
      File.delete(topo52)
    end               
    
    omf52file=File.open(topo52,"w")
    omf53file=File.open(topo53,"w")
    
    omf52file.write("[")
     
    @nodes.each do |node|
      
      omf52file.write("[#{node.x},#{node.y}]")
      #omf53file.write("\ttopo.addNode(\"#{NodeName(node.x,node.y)}\")\n")
      omf53file.write(@orbit.NodeName(node.x,node.y))
      
      if @nodes[@nodes.size-1]!=node
	omf52file.write(",")
	omf53file.write(",")
      end
    end 
    
    omf52file.write("]")
    #omf53file.write("\nend")
    
    omf52file.close
    omf53file.close
    
    @orbit.log("Created files describing topo: #{topo52}, #{topo53}")
    
  end
	
	private

  	# read the topology from a file
	# the file contains the list of nodes, their position and the number of interfaces they own
	# the format of each line is: A|G|R xpos ypos numRadios
	# A stands for aggregator device; G stands for gateway device; R stands for router
  	def ReadTopo(topo)

    		file=File.new(topo, "r")

    		# reading nodes information
    		while (line = file.gets)
      			line.chomp!("\n")
      			if (line.size==0 or line.strip[0].chr=='#')
				next
      			end
	
      			a=line.split(" ")
      
			if a.size()>0

				if (@orbit!=nil and not @dontcreate)				
					node = 	@orbit.AddNode(a[0], Integer(a[1]), Integer(a[2]), Integer(a[3]) )
				else
					puts "Adding node #{@nodes.size}."
					node = Node.new(@nodes.size, a[0], Integer(a[1]), Integer(a[2]), Integer(a[3]))
				end

				
				@nodes << node

				#D stands for destination, S for source and R for router
				if (a[0]=="D")
					@receivers << node
				elsif (a[0]=="S")
					@senders << node
				elsif (a[0]=="R")
				  
				elsif (a[0]=="G")
					@receivers << node
				elsif (a[0]=="A")
					@senders << node
				else
					puts "Error: wrong node type: #{a[0]}."
					exit 1
				end
	
      			end


		end    

		file.close


  end


  def CreateVarFile
    
    file=File.open("topology-var.sh","w")
    file.write("TOPOLOGY_FILES=\"#{@topoFile}")
    
    if (@linksFile!=nil)
      file.write(",#{@linksFile}")
    end
    file.puts("\"")
    
    file.write("RECEIVERS=\"")
    @receivers.each do |receiver|
      file.write(receiver.id)
      file.write(" ")
    end
    file.write("\"\n")
    
    file.write("SENDERS=\"")
    @senders.each do |sender|
      file.write(sender.id)
      file.write(" ")
    end
    file.write("\"\n")
    
    file.close
  end
  
  
	
  
end

class Link
  
    attr_accessor :from, :to, :quality, :rate
  
    def initialize(from, to, rate=6, quality=0)
      @from = from
      @to = to
      @rate = rate
      @quality = quality
    end


  end
       

  
 class Address
    
    attr_accessor :ip, :netmask, :interface
    
    def initialize(ip,netmask,interface)
      @ip=ip
      @netmask=netmask
      @interface=interface
    end
    
  end
  
end


if __FILE__ == $0

  if ARGV.size<3
	puts "#{__FILE__} topofile range linkFileName(which is created)."
	exit 1
  end
  
  topo=Orbit::Topology.new(ARGV[0])
  
  topo.SetRate(6)
  
  topo.AddLinksInRange(Integer(ARGV[1]))
  
  topo.CreateLinkFile(ARGV[2])
  
end

