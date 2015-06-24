
def Distance(nodeA,nodeB)

  return Math.sqrt( (nodeA.x-nodeB.x)**2 + (nodeA.y-nodeB.y)**2 )

end

#check if two unidirectional links are equals
def Equals(linkA, linkB)
  if (linkA.from == linkB.from and linkA.to==linkB.to)
    return true
  else
    return false
  end
end


#make a string of comma separated elements
def MakeStrList(array)
   result=""
   array.each do |el|
	result="#{result}#{el},"
   end
   result.chomp!(",")
end

