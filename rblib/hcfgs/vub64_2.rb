#!/usr/bin/ruby
#
#  vub64_2.rb
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#

module Shwrap

	LHPO = Platform.new("vub64_2","64","VirtualBox")
	LHOSO = OS.new("Ubuntu","Debian","x86_64","GNU/Linux")
	HostO = TestHost.new("192.168.0.8","vub64v2",LHOSO)
	#HostO = TestHost.new("192.168.33.138","localhost",LHOSO)

end
