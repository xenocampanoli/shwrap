#!/usr/bin/ruby
#
#  eskimodotcom.rb
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#

module Shwrap

	LHPO = Platform.new("eskimodotcom","32","Hardware")
	LHOSO = OS.new("SunOS","WhoKnows","WhoKnows","SunOS")
	HostO = TestHost.new("204.122.16.13","eskimo.com",LHOSO)

end
