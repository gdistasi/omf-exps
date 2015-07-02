require 'date'

exp="./scripts/make_exps_new.rb"
exp_opt="scripts/expCommMagReview.rb"
#Schedule experiment #{exp} to be performed on ORBIT from ARGV[0] to ARGV[1]. #{exp} must be a script already loaded on ORBIT.

start_time=DateTime.parse(ARGV[0])
stop_time=DateTime.parse(ARGV[1])

local_start_str=(start_time+5/24.0).strftime("%H:%M")
stop_time_str=stop_time.strftime("%H:%M")

if not File.exists?(exp)
  $stderr.puts("File #{exp} does not exist!")
  exit(1)
end

cmd = "echo ./scripts/schedule_exps_new.sh ORBIT #{exp} #{exp_opt} #{stop_time_str} | at #{local_start_str} "

puts "Scheduling thorough #{cmd}"

system(cmd)


