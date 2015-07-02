

def GetExps(defaults)
  
  exps=Array.new
  
  initCaOption="0-0-3,0-1-4,1-0-2,1-1-5,2-0-3,2-1-5,3-0-1,3-1-3,4-0-1,4-1-6,5-0-1,5-1-4,6-0-2,6-1-4,7-0-2,7-1-6,8-0-3,8-1-4,9-0-5,9-1-6,10-0-3,10-1-5,11-0-1,11-1-2,12-0-4,12-1-5"

  changes=["12-4-7,5-4-7","3-3-4","0-3-5","5-1-6","8-4-2"]

  new_exp_defaults = "--initialAlgo MA --initialAlgoOption #{initCaOption}"

  for i in 1..5
  
    
    temp = "--caOption "
    
    for k in  1..i
      
      temp="#{changes[i]},"
  
    end
    
    temp="#{temp},S"
    
    exps << "#{defaults} #{new_exp_defaults} #{temp}"
    
  end
    
end