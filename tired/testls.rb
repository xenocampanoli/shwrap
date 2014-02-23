#
#	testls.rb 
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
	puts "USAGE:  ruby test_shell_cmds.rb <TestHost>"
	puts "  <TestHost> is for now strictly the IP address of the host."
	exit 1
end
TestHost	= validateTestHost(ARGV[0])
TuEx		= true

require './Shwrap.rb'
require "./#{TestHost}.rb"

AdminUser='root'
TestUser='root'
AccO = Shwrap::TestAccess.new(Shwrap::HostO,AdminUser,TestUser)
# Must have keyed passwordless ssh access for this to work well:
AccO.sshTestUserOnHost
# Define test monitors:

TmpDir = "/tmp/shwraptestdir"

AccO.redirectRemote("rm -rf #{TmpDir};mkdir -p #{TmpDir};touch #{TmpDir}/tf;date > #{TmpDir}/d.lst","makeplaydata")
tlsf = "#{TmpDir}/ls.lst"
AccO.shwrapCap("touch #{tlsf}",true)
tailto = Shwrap::TailMonitor.new(AccO,TmpDir,"ls.lst")
to = Shwrap::Tester.new(AccO,"ls -al #{TmpDir} >#{tlsf}",[tailto],TuEx,24)
puts to.Result
puts to.MonOs[tailto].Result

