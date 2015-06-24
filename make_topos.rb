
if ARGV.size!=7
  puts "Usage: make_topos.rb numNodes xdim ydim minDist maxDist onlyOdd alsoCPU"
  exit 1
end

$numNodes=Integer(ARGV[0])
$xdim=Float(ARGV[1])
$ydim=Float(ARGV[2])
$minDist=Float(ARGV[3])
$maxDist=Float(ARGV[4])
$onlyOdd=Integer(ARGV[5])==1
$alsoCPU=Integer(ARGV[6])==1

$minX=$xdim
$maxX=0
$minY=$ydim
$maxY=0

nodes=Array.new

$nodes_off_file="nodes_off"


class Node 
  
  attr_accessor :x, :y
    
  def initialize(x, y)
    @x = x
    @y = y
    @type = "R"
  end
    
  def distance(node)
     return Math.sqrt( (node.x-@x)**2 + (node.y-@y)**2 )
  end
  
end
  

def minDistance(nodes, node)
    dist= $xdim + $ydim;
  
    nodes.each do |n|
       if (n.x==node.x and n.y==node.y) 
	 next
       end
	  
       minDist=n.distance(node)
               
       #puts "#node0: #{node.x}:#{node.y} node1: #{n.x}:#{n.y}. distance #{minDist}"
       if (minDist<dist) then
	dist=minDist
       end
        #end
    end
    return dist
end



def IsOff(x,y)
  return $nodes_off.include?("#{x}_#{y}")
end

def AlreadyIn(nodes,x,y)
  
  nodes.each do |node|
      if (node.x==x and node.y==y)
	return true
      end
  end
  
  return false
  
end

def stats(nodes)
  maxMinDistance=0
  minMinDistance=$xdim + $ydim
  
  nodes.each { |node|
            
     d=minDistance(nodes, node)
              
     if d>maxMinDistance then
	maxMinDistance=d
     elsif d<minMinDistance
	minMinDistance=d
     end

     if node.x > $maxX
       $maxX=node.x
     elsif node.x < $minX
       $minX=node.x
     end
     
     if node.y > $maxY
       $maxY=node.y
     elsif node.y < $minY
       $minY=node.y
     end

  }
  
  puts "# MaxDistance: #{maxMinDistance}"
  puts "# MinDistance: #{minMinDistance}"
  puts "# MinX: #{$minX}; MaxX: #{$maxX}"
  puts "# MinY: #{$minY}; MaxY: #{$maxY}"
  
end


#read the file with the nodes to be excluded
$nodes_off=`cat #{$nodes_off_file}`

nodes << Node.new(1+(rand()*($xdim-1)).to_i, 1+(rand()*($ydim-1)).to_i)

i=0

while nodes.size() < $numNodes
  x=1+(rand()*($xdim-1)).to_i;
  y=1+(rand()*($ydim-1)).to_i;
  

  if ($onlyOdd and (x+y)%2==0) or IsOff(x,y) or AlreadyIn(nodes, x,y)
    next
  end
  
  node=Node.new(x,y)

  dist=minDistance(nodes, node)
  
  if dist >= $minDist  and dist <= $maxDist   then
    #puts "dist #{dist} mindist #{$minDist}"
    numRadios=Random.rand(2)+2
    if $alsoCPU
      cpu=Random.rand(51)+50
    else
      cpu=""
    end
    nodes.push(node)
    
      puts "##{i}"
      puts "R #{node.x} #{node.y} #{numRadios} #{cpu}"
      i=i+1
    #puts "#size #{nodes.size}"
    #puts "#Adding node #{node.x} #{node.y}"
  end  
  
end

def define_type
  
  
end 
 
stats(nodes)

