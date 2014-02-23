#
#	test_vb.rb 
#	Copyright 2014 Xeno Campanoli
#   This code is covered under the Schwrapper.rb copyright, except that all
#	code that copies this code directly for use of Schrapper.rb as a service
#	is free from the copyright.
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#
TestHost = ARGV[0]

require 'minitest/spec'
require 'minitest/autorun'

#require 'Shwrap.rb'
require './Shwrap.rb'
require "./Resources.rb"
#require "rubygems"

# Define tests and local resource objects:

# Assign host
ho = Vdeb64i1HO
# Test host connectivity:
#	1.	host is up and pings.
ho.pingOrBlow
#	2.	root access exists
acco = Shwrap::TestAccess.new(ho,'root','xeno')
acco.sshTestAccountsOnHost
acco.sudoTestUserToRootNoPasswd

# Define test monitors:

alto = Shwrap::Monitor.new("tail -f --bytes=0 #{ho.OSO.AuthLog}")
slto = Shwrap::Monitor.new("tail -f --bytes=0 #{ho.OSO.SysLog}")

tuex = false

describe "test ls command" do
	it "it should show files in a directory by default." do
		acco.shwrapexec('rm -rf /tmp/lstestdir;mkdir -p /tmp/lstestdir;touch /tmp/lstestdir/tf;date > /tmp/lstestdir/d.lst',true)
		to = Shwrap::Tester.new(acco,"ls",[slto],tuex,1)
		to.Result.wont_be_empty
		to.Result.must_match /tf/
		to.Result.must_match /d.lst/
		to.MonOs[SLTo].Result.must_be_nil
	end
end
