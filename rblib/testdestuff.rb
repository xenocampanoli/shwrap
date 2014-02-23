#
#	testdestuff.rb 
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

						puts "head /var/log/#{Shwrap::HostO.OSO.Dmesg}"
to = Shwrap::Tester.new(AccO,"head /var/log/#{Shwrap::HostO.OSO.Dmesg}",[],TuEx,32)
puts to.Result

						puts "tail /var/log/#{Shwrap::HostO.OSO.Dmesg}"
to = Shwrap::Tester.new(AccO,"tail /var/log/#{Shwrap::HostO.OSO.Dmesg}",[],TuEx,16)
puts to.Result

to1 = Shwrap::Tester.new(AccO,"ps auxw | grep e | grep -v z | grep -c root",[],TuEx,16)
puts to1.Result
