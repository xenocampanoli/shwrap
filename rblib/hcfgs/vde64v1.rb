#!/usr/bin/ruby
#
#  vde64v1.rb
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#

module Shwrap

	LHPO = Platform.new("vde64v1","64","VirtualBox")
	LHOSO = OS.new("Debian","Debian","x86_64","GNU/Linux")
	HostO = TestHost.new("192.168.0.10","vde64v1",LHOSO)

end
