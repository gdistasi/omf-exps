

def GetExps(defaults, initCaOption,  changes,  topo, links)
  
  exps=Array.new
  
  new_exp_defaults = "--initialAlgo MA --initialAlgoOption #{initCaOption}"

  for i in 1..change.size()
  
    
    temp = "--caOption "
    
    for k in  1..i
      
      temp="#{changes[i]},"
  
    end
    
    temp="#{temp}S"
   
    exp = { "value" => "#{defaults} #{new_exp_defaults} #{temp}", "id" => "#{topo}-#{i}Changes", "topo" => topo, "links" => links, "repetitions" => 2  }
    
    exps << exp
    
  end
  
  return exps
    
end