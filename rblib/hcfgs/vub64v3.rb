#!/usr/bin/ruby
#
#  vub64v3.rb
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#

module Shwrap

	LHPO = Platform.new("vub64v3","64","VirtualBox")
	LHOSO = OS.new("Ubuntu","Debian","x86_64","GNU/Linux")
	HostO = TestHost.new("192.168.0.9","vub64v3",LHOSO)

end
