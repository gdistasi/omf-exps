




class LogCollector

  def initialize
    @files = Hash.new
  end

  
  def Add(node, file)
    @files[node.name]=Array.new unless @files[node.name]!=nil
    @files[node.name] << file
  end
  
  
  def GetFileList(node)
    if @files[node.name] == nil  
      return Array.new
    else 
      return @files[node.name].to_a
    end
  end
  
  

end
