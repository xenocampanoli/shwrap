#
#	awk_pipe_examples.rb 
#	Copyright 2014 Xeno Campanoli
#   This code is covered under the Schwrap.rb copyright.  Permanently open to
#	use by all.
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
def validateTestHost(tH)
	return tH if File.exists?("#{tH}.rb")
	raise ArgumentError, "Invalid TestHost '#{tH}'."
end
unless ARGV.length == 1
	puts "USAGE:  ruby test_shell_cmds.rb <TestHost> <TestUserExecuting>"
	puts "  <TestHost> is for now strictly the IP address of the host."
	exit 1
end
TestHost	= validateTestHost(ARGV[0])
TuEx		= true

require './Shwrap.rb'
require "./#{TestHost}.rb"

AdminUser='xeno'
TestUser='xeno'
AccO = Shwrap::TestAccess.new(Shwrap::HostO,AdminUser,TestUser)
# Must have keyed passwordless ssh access for this to work well:
AccO.sshTestUserOnHost
# Define test monitors:
DLTO = Shwrap::TailMonitor.new(AccO,'/var/log',Shwrap::HostO.OSO.Dmesg)

to1 = Shwrap::Tester.new(AccO,"ps | awk \"{print \\$1}\"",[],TuEx,8)
puts "trace to1.Result:\n#{to1.Result}"
to2 = Shwrap::Tester.new(AccO,"free | grep Mem: | awk \"{print \\$3}\"",[],TuEx,8)
puts "trace to2.Result:\n#{to2.Result}"
to3 = Shwrap::Tester.new(AccO,"free | grep Swap: | awk \"{print \\$3}\"",[],TuEx,8)
puts "trace to3.Result:\n#{to3.Result}"
to4 = Shwrap::Tester.new(AccO,"ps auxw | grep grep | awk \"{print \\$2}\"",[],TuEx,16)
puts "trace to4.Result:\n#{to4.Result}"
to5 = Shwrap::Tester.new(AccO,"ps auxw | grep #{TestUser} | awk \"{print \\$1}\"",[],TuEx,8)
puts "trace to5.Result:\n#{to5.Result}"
to6 = Shwrap::Tester.new(AccO,"ps auxw | grep #{AdminUser} | awk \"{print \\$1}\"",[],TuEx,8)
puts "trace to6.Result:\n#{to6.Result}"

# End of user_test_shell_cmds.rb
