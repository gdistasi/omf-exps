#!/usr/bin/env ruby
# The script merges two dat files produced by ITGDec by summing up the Aggregate-flow columns of the two files

require 'getoptlong'

values = Array.new
times = Array.new

def usage()
  puts "sum.rb --sum|--average [--skipline] file0.dat file1.dat [file2.dat, ...]"
end

if ARGV.size<2 
  usage()
  exit 1
end

if ARGV[0]=="--sum"
	dosum=true
elsif ARGV[0]=="--average"
	doaverage=true
else
        usage()
	exit(1)
end

ARGV.delete_at(0)

if ARGV[0]=="--skipline"
   skipline=true
   ARGV.delete_at(0)
#   $stderr.write "Skipping first line\n"
else
   skipline=false
end

files=Array.new

#open all the files
ARGV.each do |filename|
	files << File.open(filename)
end

numFiles=files.size

#read the first line for all the files
if (skipline)
  files.each do |file|
     file.gets
  end
end

#merge the files
files[0].each_line do |line|
  #start writing the time

  lineEl=line.split(" ")
  time=lineEl[0]
  sum=Float(lineEl[-1].chomp)  
 
  #then write the samples from the files
  files[1,files.size-1].each do |file|
     lineTemp=file.gets

     if (lineTemp==nil)
	     $stderr.write("Warning: reached the end file #{ARGV[files.index(file)]} \n")
	     file.close()
	     files.delete(file)
	     next
     end     

     lineEl=lineTemp.split(" ")
     
     timeN=lineEl[0]

     if (timeN!=time)
 	$stderr.write "Error: time samples do not coincide\n"
     end

     sum=sum+Float(lineEl[-1])
     
  end	   

  times << time
  values << sum


end


files.each do |file|
   file.close()
end

#Writing result on the stdout
#puts "Time Aggregate-Flows"
i=0
times.each do |time|
  if (dosum)
	  puts "#{time} #{values[i]}"
  else
 	  puts "#{time} #{values[i]/numFiles}"
  end  

  i=i+1
end

