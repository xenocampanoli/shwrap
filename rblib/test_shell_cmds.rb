#
#	test_shell_cmds.rb 
#	Copyright 2014 Xeno Campanoli
#   This code is covered under the Schwrapper.rb copyright, except that all
#	code that copies this code directly for use of Schrapper.rb as a service
#	is free from the copyright.
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#
def validateTestEx(tE)
	return false	if tE == "false"
	return "sudo"	if tE == "sudo"
	return true		if tE == "true"
	raise ArgumentError, "Invalid TestUser Executing Flag '#{tE}'."
end
def validateTestHost(tH)
	return tH if File.exists?("#{tH}.rb")
	raise ArgumentError, "Invalid TestHost '#{tH}'."
end

unless ARGV.length >= 2
	puts "USAGE:  ruby test_shell_cmds.rb <TestHost> <TestUserExecuting>"
	puts "  <TestHost> is for now strictly the IP address of the host."
	puts "  <TestUserExecuting> is one of {false or nil, true, or sudo}."
	exit 1
end
TestHost	= validateTestHost(ARGV[0])
TuEx		= validateTestEx(ARGV[1])

require 'minitest/spec'
require 'minitest/autorun'

require './Shwrap.rb'
require "./#{TestHost}.rb"

AccO = Shwrap::TestAccess.new(Shwrap::HostO,'root','xeno')
# Must have keyed passwordless ssh access for this to work well:
AccO.sshTestAccountsOnHost

# Define test monitors:

ALTO = Shwrap::TailMonitor.new(AccO,'/var/log',Shwrap::HostO.OSO.AuthLog)
SLTO = Shwrap::TailMonitor.new(AccO,'/var/log',Shwrap::HostO.OSO.SysLog)

TmpDir = "/tmp/shwraptestdir"

describe "unix commands work fine." do

	after do
		AccO.shwrapCap("rm -rf #{TmpDir}")
		AccO.cleanTmp
	end

	before do
		AccO.redirectRemote("rm -rf #{TmpDir};mkdir -p #{TmpDir};touch #{TmpDir}/tf;date > #{TmpDir}/d.lst","makeplaydata")
	end

	describe "test awk command" do
		it "should allow you to pull a column off a stream." do
			to = Shwrap::Tester.new(AccO,"ps | awk \'{print \$1}\'",[],TuEx,8)
			to.Result.must_match /PID/
			to.Result.must_match /\d+/
		end
	end

	describe "test cksum command" do
		it "should provide you a large sized checksum, file size, and filespec." do
			to = Shwrap::Tester.new(AccO,"cksum /etc/hosts",[],TuEx,8)
			to.Result.must_match /^\d+\s+\d+\s+\/etc\/hosts$/
		end
	end

	describe "test curl command" do
		it "should print markup for a file at an HTTP URL." do
			to = Shwrap::Tester.new(AccO,"curl http://www.google.com",[],TuEx,16)
			to.Result.must_match /<html/
			to.Result.must_match /<\/html>/
		end
	end

	describe "test curl command" do
		it "should print markup for a file at an HTTP URL." do
			to = Shwrap::Tester.new(AccO,"curl http://www.google.com",[],TuEx,8)
			to.Result.must_match /<html/
			to.Result.must_match /<\/html>/
		end
	end

	describe "test date command" do
		it "should give you date/time information in a wide range of formats." do
			to1 = Shwrap::Tester.new(AccO,"date +Y",[],TuEx,8)
			to1.Result.must_match /^\d{4}$/
			to2 = Shwrap::Tester.new(AccO,"date",[],TuEx,8)
			to2.Result.must_match /\d{4}/
		end
	end

	describe "test df command" do
		it "should print space usage for filesystems." do
			to1 = Shwrap::Tester.new(AccO,"df",[],TuEx,8)
			#to1.Result.must_match /Filesystem\s+1K-blocks\s+Used\s+Available\s+Use%\s+Mounted on/
			to1.Result.must_match /\/dev\//
			to1.Result.must_match /\s+\d+%\s+/
			to1.Result.must_match /\s+\d+\s+/
			to2 = Shwrap::Tester.new(AccO,"df -P",[],TuEx,8)
			to2.Result.must_match /Filesystem\s+1024-blocks\s+Used\s+Available\s+Capacity\s+Mounted on/
			to2.Result.must_match /\/dev\//
			to2.Result.must_match /\s+\d+%\s+/
			to2.Result.must_match /\s+\d+\s+/
			to3 = Shwrap::Tester.new(AccO,"df / | grep -v Filesystem | awk \'{print \$2}\'",[],TuEx,8)
			to3.Result.must_match /^\d+$/
		end
	end

	describe "test dmesg command" do
		it "should print startup and other internals information." do
			to = Shwrap::Tester.new(AccO,"dmesg",[ALTO,SLTO],TuEx,8)
			to.Result.wont_be_empty
			to.MonOs[ALTO].Result.must_be_empty
			to.MonOs[SLTO].Result.must_be_empty
		end
	end

	describe "test du command" do
		it "should give you disk usage information for a path." do
			to = Shwrap::Tester.new(AccO,"du -s /etc",[],TuEx,8)
			to.Result.must_match /^\d{4}$/
		end
	end

	describe "test env command" do
		it "should give you a list of defined shell environment identifiers." do
			to = Shwrap::Tester.new(AccO,"env",[],TuEx,8)
			to.Result.must_match /DISPLAY=/
			to.Result.must_match /EDITOR=/
			to.Result.must_match /HOME=/
			to.Result.must_match /LANGUAGE=/
			to.Result.must_match /PATH=/
			to.Result.must_match /PWD=/
			to.Result.must_match /SHLVL=/
			to.Result.must_match /TERM=/
			to.Result.must_match /USER=/
		end
	end

	describe "test file command" do
		it "should provide simple information about the file." do
			to = Shwrap::Tester.new(AccO,"file /etc/hosts",[],TuEx,8)
			to.Result.must_match /^\/etc\/hosts\s+ASCII text$/
		end
	end

	describe "test find command" do
		it "should look up sets of files from a directory tree." do
			to1 = Shwrap::Tester.new(AccO,"find /etc -name hosts 2>/dev/null",[],TuEx,8)
			to1.Result.must_match /\/etc\/hosts/
			to2 = Shwrap::Tester.new(AccO,"find /dev -type b",[],TuEx,8)
			to2.Result.length.wont_be_empty
			to3 = Shwrap::Tester.new(AccO,"find /usr -type d -name bin",[],TuEx,8)
			to3.Result.length.must_match /bin/
		end
		it "should allow other commands to access files from a directory tree." do
			to = Shwrap::Tester.new(AccO,"ls \$(find /dev -type c 2>/dev/null) | wc -l",[],TuEx,8)
			to3.Result.must_match /^\d+$/
		end
	end

	describe "test free command" do
		it "should provide memory and virtual memory information." do
			to1 = Shwrap::Tester.new(AccO,"free",[ALTO,SLTO],TuEx,8)
			to1.Result.must_match /\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+/
			to1.MonOs[ALTO].Result.must_be_empty
			to1.MonOs[SLTO].Result.must_be_empty
		end
		it "should provide memory and virtual memory information." do
			to1 = Shwrap::Tester.new(AccO,"free | grep Mem: | awk \'{print \$3}\'",[],TuEx,8)
			to1.MonOs[SLTO].Result.must_match /^\d+$/
			to2 = Shwrap::Tester.new(AccO,"free | grep Swap: | awk \'{print \$3}\'",[],TuEx,8)
			to2.MonOs[SLTO].Result.must_match /^\d+$/
		end
	end

	describe "test grep command" do
		it "should filter text for a string." do
		end
		it "should allow for searching for a file containing a string." do
		end
	end

	describe "test groups command" do
		it "should show groups the user has access to." do
		end
	end

	describe "test head command" do
		it "should show the head (or start) of a file." do
			to = Shwrap::Tester.new(AccO,"head #{Shwrap::HostO.OSO.SysLog}",[],TuEx,8)
		end
	end

	describe "test history command" do
		it "should show groups the user has access to." do
		end
	end

	describe "test hostname command" do
		it "should show the assigned hostname also seen in $HOSTNAME." do
		end
	end

	describe "test id command" do
		it "should show the numeric id for the user and groups associated with the user." do
			to = Shwrap::Tester.new(AccO,"id",[],TuEx,8)
			to.Result.must_match /^uid=\d+\(#{TestUser}\) gid=\d+\(#{TestUser}\) groups=\d+(\w+)\),\d+(\w+)\),\d+(\w+)\)/
		end
	end

	describe "test ifconfig command" do
		it "should show assigned network configurations for a NIC." do
			to = Shwrap::Tester.new(AccO,"ifconfig",[],TuEx,16)
			to.Result.must_match /lo\s+Link encap:Local Loopback/
			to.Result.must_match /inet addr:127.0.0.1/
		end
	end

	describe "test ls command" do
		it "should show files in a directory by default." do
			to = Shwrap::Tester.new(AccO,"ls #{TmpDir}",[ALTO,SLTO],TuEx,8)
			to.Result.must_match /tf/
			to.Result.must_match /d.lst/
			to.MonOs[ALTO].Result.wont_be_empty
			to.MonOs[SLTO].Result.must_be_empty
		end
		it "should write to standard out." do
			tlsf = "#{TmpDir}/ls.lst"
			AccO.shwrapCap("touch #{tlsf}",true)
			tailto = Shwrap::TailMonitor.new(AccO,TmpDir,"ls.lst")
			to = Shwrap::Tester.new(AccO,"ls -al #{TmpDir} >#{tlsf}",[tailto],TuEx,8)
			to.Result.must_be_empty
			to.MonOs[tailto].Result.must_match /tf/
			to.MonOs[tailto].Result.must_match /d.lst/
		end
		it "should show detailed listings of files." do
		end
		it "should show directories only with -d." do
		end
	end

	describe "test lsof command" do
		it "should show list of Process Ids of open files with -t." do
		end
	end

	describe "test md5sum command" do
		it "should provide an MD5 type hash sum on a file." do
		end
	end

	describe "test netstat command" do
		it "should print network information." do
		end
	end

	describe "test nslookup command" do
		it "should print DNS information." do
		end
	end

	describe "test ping command" do
		it "should print ICMP information." do
		end
	end

	describe "test printf command" do
		it "should format data and print it." do
		end
	end

	describe "test ps command" do
		it "should show system process information." do
		end 
	end

	describe "test pwd command" do
		it "should show the present working directory." do
		end 
	end

	describe "test quota command" do
		it "should show quota information." do
		end 
	end

	describe "test sed command" do
		it "should substitute data in a string." do
		end 
	end

	describe "test seq command" do
		it "should print a sequence of numbers." do
		end 
	end

	describe "test sha1sum command" do
		it "should provide an SHA1 type hash sum on a file." do
		end
	end

	describe "test sleep command" do
		it "should cause a script to pause for a specified number of seconds." do
		end
	end

	describe "test sum command" do
		it "should provide a relatively small, primitive ckeck sum on a file, as well as a byte count." do
		end
	end

	describe "test tail command" do
		it "should show the tail end of a file." do
		end
	end

	describe "test tar command" do
		it "should create an archive file." do
		end 
		it "should re-read and extract contents from an archive file." do
		end 
	end

	describe "test time command" do
		it "should show system resource use by a command." do
		end 
	end

	describe "test timeout command" do
		it "should provide a timeout for execution of a command." do
			to1 = Shwrap::Tester.new(AccO,"timeout 1 sleep 2; echo $?",[],TuEx,8)
			to2 = Shwrap::Tester.new(AccO,"timeout 3 sleep 2; echo $?",[],TuEx,8)
		end 
	end

	describe "test times command" do
		it "should show process times used by a command." do
		end 
	end

	describe "test touch command" do
		it "should update a file's access time." do
		end 
		it "should make sure a file exists." do
		end 
	end

	describe "test tr command" do
		it "should filter a set of characters in a file." do
		end 
		it "should delete a set of characters in a file." do
		end 
	end

	describe "test traceroute command" do
		it "should report on routine to an IP address." do
		end 
	end

	describe "test tty command" do
		it "should report on terminal connected to standard input." do
		end 
	end

	describe "test umask command" do
		it "should report on umask." do
		end 
		it "should set umask." do
		end 
	end

	describe "test uname command" do
		it "should show system naming information." do
		end 
	end

	describe "test uniq command" do
		it "should filter a sorted list to have only uniq consecutive items." do
		end 
	end

	describe "test uptime command" do
		it "should tell how long the system has been running." do
		end 
	end

	describe "test users command" do
		it "should tell all the users presently logged into the host." do
		end 
	end

	describe "test vmstat command" do
		it "should show virtual memory information." do
			to = Shwrap::Tester.new(AccO,"vmstat",[],TuEx,4)
		end 
	end

	describe "test wc command" do
		it "should provide a count of characters, words and lines." do
			to = Shwrap::Tester.new(AccO,"wc /etc/hosts",[ALTO,SLTO],TuEx,4)
			to.Result.must_match /^\d+\s+\d+\s+\d+\s+\/etc\/hosts$/
		end 
		it "should provide a count of characters alone." do
			to = Shwrap::Tester.new(AccO,"wc -c /etc/hosts",[ALTO,SLTO],TuEx,4)
			to.Result.must_match /^\d+\s+\/etc\/hosts$/
		end 
		it "should provide a count of words alone." do
			to = Shwrap::Tester.new(AccO,"wc -w /etc/hosts",[ALTO,SLTO],TuEx,4)
			to.Result.must_match /^\d+\s+\/etc\/hosts$/
		end 
		it "should provide a count of lines alone." do
			to = Shwrap::Tester.new(AccO,"wc -l /etc/hosts",[ALTO,SLTO],TuEx,4)
			to.Result.must_match /^\d+\s+\/etc\/hosts$/
		end 
		it "should provide a the counts without filenames from a stream." do
			to1 = Shwrap::Tester.new(AccO,"echo test | wc",[ALTO,SLTO],TuEx,4)
			to1.Result.must_match /^1\s+1\s+5$/
			to2 = Shwrap::Tester.new(AccO,"echo -n test | wc",[ALTO,SLTO],TuEx,4)
			to2.Result.must_match /^1\s+1\s+4$/
		end
	end

	describe "test which command" do
		it "should show a path for a command if it exists and is accessible via $PATH." do
			to = Shwrap::Tester.new(AccO,"which which",[ALTO,SLTO],TuEx,4)
			to.Result.must_match /^\//
			to.Result.must_match /which$/
		end 
	end

	describe "test whoami command" do
		it "should show the name of the user for the present shell." do
			to = Shwrap::Tester.new(AccO,"whoami",[ALTO,SLTO],TuEx,4)
			to.Result.must_match /^\w+$/
		end 
	end

	describe "test wget command" do
		it "should write a file with contents of the markup for an HTTP URL." do
			to = Shwrap::Tester.new(AccO,"wget -o /tmp/wgettest.log -O /tmp/wgettest.html http://www.google.com",[ALTO,SLTO],TuEx,4)
		end 
	end

	describe "test xargs command" do
		it "should receive data and provide these as arguments to a command." do
			to = Shwrap::Tester.new(AccO,"find /etc -type f -name '*host*' -print | xargs grep host",[],TuEx,4)
		end 
	end

	describe "test yes command" do
		it "should write the specified string continuously until killed." do
			to = Shwrap::Tester.new(AccO,"timeout 1 yes 'test string'",[ALTO,SLTO],TuEx,4)
			to.Result.must_match /test string/
		end
	end

end
