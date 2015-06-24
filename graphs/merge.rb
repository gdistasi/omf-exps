#!/usr/bin/env ruby

# Merge two or more DITG .dat files.
# The resulting file has as many columns as the number of  files in input plus the first column with the time samples.

files=Array.new

#open all the files
ARGV.each do |filename|
	files << File.open(filename)
end

#merge the files
files[0].each_line do |line|
  #start writing the time

  lineEl=line.split(" ")
  time=lineEl[0]
  a="#{time} #{lineEl[-1].chomp}"  

  #then write the samples from the files
  files[1,files.size-1].each do |file|

     lineTemp=file.gets

     if (lineTemp==nil)
	     a="#{a} 0"
	     next
     end

     lineEl=lineTemp.split(" ")

     timeN=lineEl[0]
     if (timeN!=time)
 	$stderr.write "Error: time samples do not coincide\n"
     end

     a="#{a} #{lineEl[-1].chomp}"
  end	   

  puts a

end


files.each do |file|
   file.close()
end
