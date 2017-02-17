




class LogCollector

  def initialize
    @files = Hash.new
  end

  
  def Add(node, file)
    @files[node]=Array.new unless @files[node]!=nil
    @files[node] << file
  end
  
  
  def GetFileList(node)
    if @files[node] == nil  
      return Array.new
    else 
      return @files[node].to_a
    end
  end
  
  

end
