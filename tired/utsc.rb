#
#	user_test_shell_cmds.rb 
#	Copyright 2014 Xeno Campanoli
#   This code is covered under the Schwrapper.rb copyright.  Permanently open to
#	use by all.
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#
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

require 'minitest/spec'
require 'minitest/autorun'

require './Shwrap.rb'
require "./#{TestHost}.rb"

AccO = Shwrap::TestAccess.new(Shwrap::HostO,'xeno','xeno')
# Must have keyed passwordless ssh access for this to work well:
AccO.sshTestUserOnHost

# Define test monitors:

DLTO = Shwrap::TailMonitor.new(AccO,'/var/log',Shwrap::HostO.OSO.Dmesg)

TmpDir = "/tmp/shwraptestdir"

describe "unix commands work fine." do

	describe "test awk command" do
		it "should allow you to pull a column off a stream." do
			to = Shwrap::Tester.new(AccO,"ps | awk \"{print \\$1}\"",[],TuEx,8)
			to.Result.must_match /PID/
			to.Result.must_match /\d+/
		end
	end

end
