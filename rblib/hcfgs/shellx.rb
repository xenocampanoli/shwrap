#!/usr/bin/ruby
#
#  shellx.rb
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#

module Shwrap

	LHPO = Platform.new("shellx","32","Hardware")
	LHOSO = OS.new("CentOS","RedHat","x86_64","GNU/Linux")
	HostO = TestHost.new("204.122.16.5","shellx.eskimo.com",LHOSO)

end
