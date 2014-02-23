#
#	test_vb_H.rb 
#	Copyright 2014 Xeno Campanoli
#   This code is covered under the Schwrapper.rb copyright, except that all
#	code that copies this code directly for use of Schrapper.rb as a service
#	is free from the copyright.
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#
TestHost = ARGV[0]

require './Shwrap.rb'
require "./#{TestHost}.rb"

Shwrap::HostO.pingOrBlow
AccO = Shwrap::TestAccess.new(Shwrap::HostO,'root','xeno')
AccO.sshTestAccountsOnHost
AccO.sudoTestUserToRootNoPasswd

# Define test monitors:

tuex = false

TmpDir = "/tmp/shwrapdir"
tlsf = "#{TmpDir}/ls.lst"
AccO.shwrapCap("rm -rf #{TmpDir};mkdir -p #{TmpDir};touch #{tlsf};date > #{TmpDir}/d.lst",true)
AccO.shwrapCap("touch #{tlsf}",true)

tailto = Shwrap::TailMonitor.new(AccO,TmpDir,"ls.lst")

to = Shwrap::Tester.new(AccO,"ls #{TmpDir} >>#{tlsf}",[tailto],tuex,10)
puts "trace test Result:  #{to.Result}"
puts "trace test Status:  #{to.Status}"
puts "trace test StdErr:  #{to.StdErr}"
puts "trace Monitor Tail: #{to.MonOs[tailto].Result}"
AccO.shwrapCap("rm -rf #{TmpDir}",false)
