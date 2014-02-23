#
#	vbx_test_logtail.rb 
#	Copyright 2014 Xeno Campanoli
#   This code is covered under the Schwrap.rb copyright.  Permanently open to
#	use by all.
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#
def validateTestHost(tH)
	return tH if File.exists?("#{tH}.rb")
	raise ArgumentError, "Invalid TestHost '#{tH}'."
end

unless ARGV.length == 2
	puts "USAGE:  ruby vbx_test_logtail.rb <TestHost> <UserName>"
	puts "  <TestHost> is for now strictly the IP address of the host."
	puts "  <UserName> is the user under test."
	exit 1
end
TestHost	= validateTestHost(ARGV[0])
AdminUser	= 'root'
TestUser	= ARGV[1]
TuEx		= true

require 'minitest/spec'
require 'minitest/autorun'

require './Shwrap.rb'
require "./#{TestHost}.rb"

AccO = Shwrap::TestAccess.new(Shwrap::HostO,AdminUser,TestUser)
# Must have keyed passwordless ssh access for this to work well:
AccO.pingOrBlow
AccO.sshTestUserOnHost

# Define test monitors:

DLTO = Shwrap::TailMonitor.new(AccO,'/var/log',Shwrap::HostO.OSO.Dmesg)

TmpDir = "/tmp/shwraptestdir"
AccO.redirectRemote("rm -rf #{TmpDir}","precleantmp1")
AccO.redirectRemote("rm -f /tmp/shwrap_*","precleantmp1")

describe "unix commands work fine." do

	describe "test awk command" do
		it "should allow you to pull a column off a stream." do
			to = Shwrap::Tester.new(AccO,"ps | awk \"{print \\$1}\"",[],TuEx,16)
			to.Result.must_match /PID/
			to.Result.must_match /\d+/
		end
	end

	describe "test cksum command" do
		it "should provide you a large sized checksum, file size, and filespec." do
			to = Shwrap::Tester.new(AccO,"cksum /etc/hosts",[],TuEx,24)
			to.Result.must_match /^\d+\s+\d+\s+\/etc\/hosts$/
		end
	end

	describe "test date command" do
		it "should give you date/time information in a wide range of formats." do
			to1 = Shwrap::Tester.new(AccO,"date +%Y",[],TuEx,16)
			to1.Result.chomp.must_match /^\d{4}$/
			to2 = Shwrap::Tester.new(AccO,"date",[],TuEx,16)
			to2.Result.must_match /\d{4}/
		end
	end

	describe "test df command" do
		it "should print space usage for filesystems." do
			to1 = Shwrap::Tester.new(AccO,"df",[],TuEx,16)
			#to1.Result.must_match /Filesystem\s+1K-blocks\s+Used\s+Available\s+Use%\s+Mounted on/
			to1.Result.must_match /\/dev\//
			to1.Result.must_match /\s+\d+%\s+/
			to1.Result.must_match /\s+\d+\s+/
			to2 = Shwrap::Tester.new(AccO,"df -P",[],TuEx,16)
			to2.Result.must_match /Filesystem\s+1024-blocks\s+Used\s+Available\s+Capacity\s+Mounted on/
			to2.Result.must_match /\/dev\//
			to2.Result.must_match /\s+\d+%\s+/
			to2.Result.must_match /\s+\d+\s+/
			to3 = Shwrap::Tester.new(AccO,"df / | grep -v Filesystem | awk \"{print \\$2}\"",[],TuEx,16)
			to3.Result.must_match /^\d+$/
		end
	end

	describe "test dmesg command" do
		it "should print startup and other internals information." do
			to = Shwrap::Tester.new(AccO,"dmesg",[DLTO],TuEx,16)
			to.Result.wont_be_empty
			to.MonOs[DLTO].Result.must_be_empty
		end
	end

	describe "test du command" do
		it "should give you disk usage information for a path." do
			to = Shwrap::Tester.new(AccO,"du -s /etc",[],TuEx,16)
			to.Result.chomp.must_match /^\d+\s+\/etc$/
		end
	end

	describe "test env command" do
		it "should give you a list of defined shell environment identifiers." do
			to = Shwrap::Tester.new(AccO,"env",[],TuEx,16)
			to.Result.must_match /HOME=/
			to.Result.must_match /PATH=/
			to.Result.must_match /PWD=/
			to.Result.must_match /SHLVL=/
			to.Result.must_match /USER=/
		end
	end

	describe "test file command" do
		it "should provide simple information about the file." do
			to = Shwrap::Tester.new(AccO,"file /etc/hosts",[],TuEx,16)
			to.Result.chomp.must_match /^\/etc\/hosts:\s+ASCII .*text$/
		end
	end

	describe "test find command" do
		it "should look up sets of files from a directory tree." do
			to1 = Shwrap::Tester.new(AccO,"find /etc -name hosts 2>/dev/null",[],TuEx,16)
			to1.Result.must_match /\/etc\/hosts/
			to2 = Shwrap::Tester.new(AccO,"find /dev -type b",[],TuEx,16)
			to2.Result.wont_be_empty
			to3 = Shwrap::Tester.new(AccO,"timeout 12 find /usr -type d -name bin",[],TuEx,24)
			to3.Result.must_match /bin/
		end
		it "should allow other commands to access files from a directory tree." do
			to = Shwrap::Tester.new(AccO,"ls $(find /dev -type c 2>/dev/null) | wc -l",[],TuEx,16)
			to.Result.chomp.must_match /^\d+$/
		end
	end

	describe "test free command" do
		it "should provide memory and virtual memory information." do
			to1 = Shwrap::Tester.new(AccO,"free",[],TuEx,16)
			to1.Result.must_match /\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+/
		end
		it "should provide memory and virtual memory information." do
			to1 = Shwrap::Tester.new(AccO,"free | grep Mem: | awk \"{print \\$3}\"",[],TuEx,16)
			to1.Result.must_match /^\d+$/
			to2 = Shwrap::Tester.new(AccO,"free | grep Swap: | awk \"{print \\$3}\"",[],TuEx,16)
			to2.Result.must_match /^\d+$/
		end
	end

	# TBD:  Need to make modifications of testing for root or non-root users.
	describe "test grep command" do
		it "should filter text for a string." do
			to1 = Shwrap::Tester.new(AccO,"ps auxw | grep e | grep -v z | grep -c root",[],TuEx,16)
			to1.Result.strip.to_i.must_be :>, 0
			to2 = Shwrap::Tester.new(AccO,"ps auxw | grep grep | awk \"{print \\$2}\"",[],TuEx,16)
			to2.Result.must_match /\d+/
		end
		it "should allow for searching for a file containing a string." do
			to = Shwrap::Tester.new(AccO,"grep -l localhost /etc/*host*",[],TuEx,16)
			to.Result.must_match /\/etc\/hosts/
		end
	end

	describe "test groups command" do
		it "should show groups the user has access to." do
			to = Shwrap::Tester.new(AccO,"groups",[],TuEx,16)
			#to.Result.must_match /^\w+\s+\w+\s+\w+/
			to.Result.must_match /^\w+/
		end
	end

	unless TuEx == true
		# TBD:  Need to make modifications of testing for root or non-root users.
		describe "test head command" do
			it "should show the head (or start) of a file." do
				to = Shwrap::Tester.new(AccO,"head /var/log/#{Shwrap::HostO.OSO.Dmesg}",[],TuEx,32)
				to.Result.wont_be_empty
			end
		end
	end

	describe "test hostname command" do
		it "should show the assigned hostname also seen in $HOSTNAME." do
			to = Shwrap::Tester.new(AccO,"hostname",[],TuEx,16)
			envhn,se,st = AccO.shwrapCap("echo \$HOSTNAME",TuEx)
			to.Result.must_match /#{envhn}/
		end
	end

	describe "test id command" do
		it "should show the numeric id for the user and groups associated with the user." do
			to = Shwrap::Tester.new(AccO,"id",[],TuEx,16)
			to.Result.must_match /uid=\d+/
			to.Result.must_match /gid=\d+/
			to.Result.must_match /groups=\d+/
		end
	end

	describe "test ls command" do
		it "should show files in a directory by default." do
			AccO.redirectRemote("rm -rf #{TmpDir};mkdir -p #{TmpDir};touch #{TmpDir}/tf;date > #{TmpDir}/d.lst","makeplaydata")
			to = Shwrap::Tester.new(AccO,"ls #{TmpDir}",[],TuEx,16)
			to.Result.must_match /tf/
			to.Result.must_match /d.lst/
		end
		it "should write to standard out." do
			AccO.redirectRemote("rm -rf #{TmpDir};mkdir -p #{TmpDir};touch #{TmpDir}/tf;date > #{TmpDir}/d.lst","makeplaydata")
			tlsf = "#{TmpDir}/ls.lst"
			AccO.redirectRemote("touch #{tlsf};chown #{TestUser} #{tlsf}","touchtesttmp")
			tailto = Shwrap::TailMonitor.new(AccO,TmpDir,"ls.lst")
			to = Shwrap::Tester.new(AccO,"ls -al #{TmpDir} >#{tlsf}",[tailto],TuEx,24)
			to.Result.must_be_empty
			to.MonOs[tailto].Result.must_match /tf/
			to.MonOs[tailto].Result.must_match /d.lst/
		end
		it "should show detailed listings of files." do
			to1 = Shwrap::Tester.new(AccO,"ls -al /dev",[],TuEx,16)
			to1.Result.wont_be_empty
			to2 = Shwrap::Tester.new(AccO,"ls -al /lib",[],TuEx,16)
			to2.Result.wont_be_empty
			to3 = Shwrap::Tester.new(AccO,"ls -al /proc",[],TuEx,16)
			to3.Result.wont_be_empty
			to4 = Shwrap::Tester.new(AccO,"ls -al /usr/bin",[],TuEx,16)
			to4.Result.wont_be_empty
			to5 = Shwrap::Tester.new(AccO,"ls -al /usr",[],TuEx,16)
			to5.Result.wont_be_empty
		end
		it "should show directories only with -d." do
			to1 = Shwrap::Tester.new(AccO,"ls -ald /dev",[],TuEx,16)
			to1.Result.must_match /\/dev/
			to2 = Shwrap::Tester.new(AccO,"ls -ald /lib",[],TuEx,16)
			to2.Result.must_match /\/lib/
			to3 = Shwrap::Tester.new(AccO,"ls -ald /proc",[],TuEx,16)
			to3.Result.must_match /\/proc/
			to4 = Shwrap::Tester.new(AccO,"ls -d /usr",[],TuEx,16)
			to4.Result.must_match /\/usr/
			to5 = Shwrap::Tester.new(AccO,"ls -ad /var",[],TuEx,16)
			to5.Result.must_match /\/var/
		end
	end

	describe "test lsof command" do
		it "should show list thousands of open file items by default.  I don't know why." do
			to1 = Shwrap::Tester.new(AccO,"lsof",[],TuEx,16)
		end
	end

	describe "test md5sum command" do
		it "should provide an MD5 type hash sum on a file." do
			to = Shwrap::Tester.new(AccO,"md5sum /etc/hosts",[],TuEx,16)
			to.Result.chomp.must_match /^[0-9a-f]{32}\s+\/etc\/hosts$/
		end
	end

	describe "test netstat command" do
		it "should print network interface information." do
			to = Shwrap::Tester.new(AccO,"netstat -i",[],TuEx,16)
			to.Result.must_match /(eth\d|lo|wlan\d)/
		end
		it "should print network statistics." do
			to = Shwrap::Tester.new(AccO,"netstat -s",[],TuEx,16)
			to.Result.must_match /Ip:/
			to.Result.must_match /Icmp:/
			to.Result.must_match /Tcp:/
			to.Result.must_match /Udp:/
		end
	end

	describe "test ping command" do
		it "should print ICMP information." do
			to = Shwrap::Tester.new(AccO,"ping -c 1 -w 2 google.com",[],TuEx,16)
			to.Result.must_match /1 packets transmitted, 1 received/
		end
	end

	describe "test printf command" do
		it "should format data and print it." do
			to = Shwrap::Tester.new(AccO,"printf \"%x\" \$(ping -c 8 -w 12 google.com | wc -c)",[],TuEx,16)
			to.Result.chomp.must_match /^[0-9a-f]+$/
		end
	end

	describe "test ps command" do
		it "should show process information." do
			to = Shwrap::Tester.new(AccO,"ps",[],TuEx,16)
			to.Result.must_match /PID\s+TTY\s+TIME\s+CMD/
			to.Result.must_match /\d+\s+\S+\s+\d{2}:\d{2}:\d{2}\s+\S+/
		end 
		it "should allow you to get to process ids for a user." do
			to1 = Shwrap::Tester.new(AccO,"ps auxw | grep #{TestUser} | awk \"{print \\$1}\"",[],TuEx,16)
			to1.Result.split(/\n/).length.must_be :>, 1
			to1.Result.must_match /#{TestUser}/
			to2 = Shwrap::Tester.new(AccO,"ps auxw | grep #{AdminUser} | awk \"{print \\$1}\"",[],TuEx,16)
			taupids = to2.Result.split(/\n/).length
			tauuniqpids = to2.Result.split(/\n/).sort.uniq.length
			#tauuniqpids.must_equal taupids
			to3 = Shwrap::Tester.new(AccO,"ps auxw | grep #{AdminUser} | awk \"{print \\$2}\"",[],TuEx,16)
			to3.Result.split(/\n/).length.must_be :>, 1
			to3.Result.must_match /\d+/
		end
	end

	describe "test pwd command" do
		it "should show the present working directory." do
			to = Shwrap::Tester.new(AccO,"cd /tmp;pwd",[],TuEx,16)
			to.Result.chomp.must_match /^\/tmp$/
		end 
	end

	describe "test sed command" do
		it "should substitute data in a string." do
			to = Shwrap::Tester.new(AccO,"which bash | sed 's:.*/::g'",[],TuEx,16)
			to.Result.chomp.must_match /^bash$/
		end 
	end

	describe "test seq command" do
		it "should print a sequence of numbers." do
			to = Shwrap::Tester.new(AccO,"seq 3",[],TuEx,16)
			to.Result.must_match /1/
			to.Result.must_match /2/
			to.Result.must_match /3/
		end 
	end

	describe "test sha1sum command" do
		it "should provide an SHA1 type hash sum on a file." do
			to = Shwrap::Tester.new(AccO,"sha1sum /etc/hosts",[],TuEx,16)
			to.Result.chomp.must_match /^[0-9a-f]{40}\s+\/etc\/hosts$/
		end
	end

	describe "test sleep command" do
		it "should cause a script to pause for a specified number of seconds." do
			to = Shwrap::Tester.new(AccO,"date >/tmp/d1.lst;sleep 1;date >/tmp/d2.lst;diff /tmp/d[12].lst",[],TuEx,16)
			to.Result.wont_be_empty
		end
	end

	describe "test sum command" do
		it "should provide a relatively small, primitive ckeck sum on a file, as well as a byte count." do
			to = Shwrap::Tester.new(AccO,"sum /etc/hosts",[],TuEx,16)
			to.Result.must_match /^\d+\s+\d+/
		end
	end

	unless TuEx == true
		# TBD:  Need to make modifications of testing for root or non-root users.
		describe "test tail command" do
			it "should show the tail end of a file." do
				to = Shwrap::Tester.new(AccO,"tail /var/log/#{Shwrap::HostO.OSO.Dmesg}",[],TuEx,16)
				to.Result.wont_be_empty
			end
		end
	end

	describe "test time command" do
		it "should show system resource use by a command." do
			to = Shwrap::Tester.new(AccO,"time cksum /etc/hosts",[],TuEx,16)
			to.Result.chomp.must_match /\d+\s+\d+\s+\/etc\/hosts/
			# Oddly, this fails over ssh apparently yielding the actual output of time to stderr.  Needs investigation.
			#to.Result.chomp.must_match /real/
			#to.Result.chomp.must_match /user/
			#to.Result.chomp.must_match /sys/
		end 
	end

	describe "test timeout command" do
		it "should provide a timeout for execution of a command." do
			to1 = Shwrap::Tester.new(AccO,"timeout 1 sleep 2; echo $?",[],TuEx,16)
			to1.Result.chomp.must_match /^124$/
			to2 = Shwrap::Tester.new(AccO,"timeout 3 sleep 2; echo $?",[],TuEx,16)
			to2.Result.chomp.must_match /^0$/
		end 
	end

	describe "test times command" do
		it "should show process times used by a command." do
			to = Shwrap::Tester.new(AccO,"times cksum /etc/hosts",[],TuEx,16)
			to.Result.split(/\n/).length.must_equal 2
			to.Result.chomp.must_match /\d+m\d+\.\d+s\s+\d+m\d+\.\d+s/
		end 
	end

	describe "test touch command" do
		it "should make sure a file exists." do
			fspec = "/tmp/arbitraryfile"
			cmd = "rm -rf #{fspec};touch #{fspec};test -e #{fspec};echo \$?"
			to = Shwrap::Tester.new(AccO,cmd,[],TuEx,24)
			to.Result.chomp.must_match /^0$/
		end 
		it "should update a file's access time." do
			to1 = Shwrap::Tester.new(AccO,"touch /tmp/touchy",[],TuEx,16)
		end 
	end

	describe "test tr command" do
		it "should filter a set of characters in a file." do
			to = Shwrap::Tester.new(AccO,"ping -c 8 -w 12 google.com | tr \"\n\" \".\"",[],TuEx,16)
			to.Result.split(/\n/).length.must_equal 1
			to.Result.wont_match /[\n]/
		end 
		it "should delete a set of characters in a file." do
			to = Shwrap::Tester.new(AccO,"ping -c 8 -w 12 google.com | tr -d \"\n\"",[],TuEx,16)
			to.Result.split(/\n/).length.must_equal 1
			to.Result.wont_match /[\n]/
		end 

	end

	describe "test umask command" do
		it "should report on umask." do
			to = Shwrap::Tester.new(AccO,"umask",[],TuEx,16)
			to.Result.chomp.must_match /^0\d{3}$/
		end 
	end

	describe "test uname command" do
		it "should show system naming information." do
			to1 = Shwrap::Tester.new(AccO,"uname -s",[],TuEx,16)
			to1.Result.chomp.must_match /^Linux$/
			to2 = Shwrap::Tester.new(AccO,"uname -n",[],TuEx,16)
			to2.Result.chomp.must_match /^#{Shwrap::HostO.HostName}$/
			to3 = Shwrap::Tester.new(AccO,"uname -r",[],TuEx,16)
			to3.Result.chomp.must_match /^\S+$/
			to4 = Shwrap::Tester.new(AccO,"uname -v",[],TuEx,16)
			to4.Result.must_match /\d+/
			to6 = Shwrap::Tester.new(AccO,"uname -m",[],TuEx,16)
			to6.Result.must_match /#{Shwrap::HostO.OSO.OSArch}/
			to7 = Shwrap::Tester.new(AccO,"uname -o",[],TuEx,16)
			to7.Result.must_match /#{Shwrap::HostO.OSO.OSType}/

			to8 = Shwrap::Tester.new(AccO,"uname -a",[],TuEx,16)
			to8.Result.must_match /\d+/
		end 
	end

	describe "test uniq command" do
		it "should filter a sorted list to have only uniq consecutive items." do
			cmd1 = "find /bin /usr/bin -print | sed 's:.*/::g' | sort | wc -l"
			to1 = Shwrap::Tester.new(AccO,cmd1,[],TuEx,16)
			to1.Result.chomp =~ /^(\d+)$/
			count1 = $1.to_i
			cmd2 = "find /bin /usr/bin -print | sed 's:.*/::g' | sort | uniq | wc -l"
			to2 = Shwrap::Tester.new(AccO,cmd2,[],TuEx,16)
			to2.Result.chomp =~ /^(\d+)$/
			count2 = $1.to_i
			assert( count1 >= count2 )
		end 
	end

	describe "test uptime command" do
		it "should tell how long the system has been running." do
			to = Shwrap::Tester.new(AccO,"uptime",[],TuEx,16)
			to.Result.must_match /\d+/
		end 
	end

	describe "test users command" do
		it "should tell all the users presently logged into the host." do
			to = Shwrap::Tester.new(AccO,"users",[],TuEx,16)
			#to.Result.must_match /#{TestUser}/
			to.Result.must_match /\w+/
		end 
	end

	describe "test vmstat command" do
		it "should show virtual memory information." do
			to = Shwrap::Tester.new(AccO,"vmstat",[],TuEx,16)
			to.Result.must_match /\d+/
		end 
	end

	describe "test wc command" do
		it "should provide a count of characters, words and lines." do
			to = Shwrap::Tester.new(AccO,"wc /etc/hosts",[],TuEx,16)
			to.Result.chomp.must_match /^\s+\d+\s+\d+\s+\d+\s+\/etc\/hosts$/
		end 
		it "should provide a count of characters alone." do
			to = Shwrap::Tester.new(AccO,"wc -c /etc/hosts",[],TuEx,16)
			to.Result.chomp.must_match /^\d+\s+\/etc\/hosts$/
		end 
		it "should provide a count of words alone." do
			to = Shwrap::Tester.new(AccO,"wc -w /etc/hosts",[],TuEx,16)
			to.Result.chomp.must_match /^\d+\s+\/etc\/hosts$/
		end 
		it "should provide a count of lines alone." do
			to = Shwrap::Tester.new(AccO,"wc -l /etc/hosts",[],TuEx,16)
			to.Result.chomp.must_match /^\d+\s+\/etc\/hosts$/
		end 
		it "should provide a the counts without filenames from a stream." do
			to1 = Shwrap::Tester.new(AccO,"echo test | wc",[],TuEx,16)
			to1.Result.chomp.must_match /^\s+1\s+1\s+5$/
			to2 = Shwrap::Tester.new(AccO,"echo -n test | wc",[],TuEx,16)
			to2.Result.chomp.must_match /^\s+0\s+1\s+4$/
		end
	end

	describe "test which command" do
		it "should show a path for a command if it exists and is accessible via $PATH." do
			to = Shwrap::Tester.new(AccO,"which which",[],TuEx,16)
			to.Result.must_match /^\//
			to.Result.must_match /which$/
		end 
	end

	describe "test whoami command" do
		it "should show the name of the user for the present shell." do
			to = Shwrap::Tester.new(AccO,"whoami",[],TuEx,16)
			to.Result.must_match /^\w+$/
		end 
	end

	describe "test wget command" do
		it "should write a file with contents of the markup for an HTTP URL." do
			to = Shwrap::Tester.new(AccO,"wget -o /tmp/wgettest.log -O /tmp/wgettest.html http://www.google.com",[],TuEx,16)
		end 
	end

	describe "test xargs command" do
		it "should receive data and provide these as arguments to a command." do
			to = Shwrap::Tester.new(AccO,"find /etc -type f -name '*host*' -print | xargs grep host",[],TuEx,16)
			to.Result.must_match /host/
		end 
	end

	describe "test yes command" do
		it "should write the specified string continuously until killed." do
			to = Shwrap::Tester.new(AccO,"timeout 1 yes t >/tmp/yest.lst;wc -l /tmp/yest.lst | awk \"{print \\$1}\"",[],TuEx,16)
			to.Result.chomp.must_match /^\d+$/
		end
	end

end

# End of user_test_logtail.rb
