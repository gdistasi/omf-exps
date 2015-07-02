
$kill_all_cmd="killall ruby; sleep 3; killall -9 ruby; sleep 2; killall scp;  "
#killall sshd; killall screen; killall bash
$ignored_users="gdistasi"
$update_cmd="nohup cd ~/l2routing/orbit && rsync -r autoexps/test_* giovanni@143.225.229.142:Tests/ &"


class User
  

  def initialize(user,log_time)
    @user=user
    @log_time=log_time
  end

  def ==(userB)
    return (@user==userB.GetName() and @log_time==userB.GetLogTime)
  end

  def GetName()
    return @user
  end

  def GetLogTime()
    return @log_time
  end
end


def GetLogged()

  users=`who`

  logged = Array.new

  users.split("\n").each do |line|
    username=line.split(" ")[0]
    log_time="#{line.split(" ")[2]} #{line.split(" ")[3]}"
    if (not $ignored_users.include?(username))
      logged << User.new(username,log_time)
    end
  end

  return logged
end

if ARGV[0] != nil 
  sleep (Integer(ARGV[0])*60) 
end

initial_logged=GetLogged()

while true
  
  logged=GetLogged()

  logged.each do |user|
    if not initial_logged.include?(user)
      #puts "New user: #{user.GetName()}! Killall procedure"
      `#{$update_cmd}`
      `#{$kill_all_cmd}`
      #`echo \"Doing killall at #{Time.now.inspect} >> ~/log_exit\"`
      exit(0)
    end
  end
  
  sleep(8)
end




