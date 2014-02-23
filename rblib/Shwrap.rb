#!/usr/bin/ruby
#
# Shwrap.rb
#
# Copyright 2014 Xeno Campanoli
#
# This software is free property; as a special exception the author
# gives unlimited permission to copy and/or distribute it, with
# or without modifications, as long as this notice is
# preserved.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
#

################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
#

require 'date'
require 'open3'
require 'timeout'

################################################################################

module Shwrap

	# Test Number Definitions:

	K = 1024
	M = K * K
	G = K * M
	T = K * G
	P = K * T

	class Platform

		attr_reader :ArchBits, :PlatformName, :PlatformType

		def initialize(nameStr,archBits,pType)
			@ArchBits = archBits
			@PlatformName = nameStr
			@PlatformType =
				case pType
					when "Hardware" then pType
					when "VirtualBox" then pType
					when "VMWare" then pType
					else raise ArgumentError, "Platform type '#{pType}' is not valid."
				end
		end

		def startBox
			cmd = nil
			case @PlatformType
				when "VirtualBox" then cmd = `VBoxManage startvm #{@PlatformName}`
				else raise ArgumentError, "Platform type '#{pType}' is not programmed for #{@PlatformName}"
			end
			`#{cmd}`
		end

	end

	class OS

		attr_reader :AuthLog, :Dmesg, :MailLog, :Name, :OSArch, :OSType, :PackageType, :SysLog

		@@AuthLog		= { 'Debian' => 'auth.log',	'RedHat' => 'secure' }
		@@Dmesg			= { 'Debian' => 'dmesg',	'RedHat' => 'dmesg' }
		@@MailLog		= { 'Debian' => 'mail.log',	'RedHat' => 'maillog' }
		@@SysLog		= { 'Debian' => 'syslog',	'RedHat' => 'messages' }
		# boot.log, dmesg, lastlog, and wtmp appear to be the same in the two flavors RedHat and Debian.
		# For now, with apache there are such wild variations I am considering that an unsolveable problem.

		def validatePackageType(pkgType)
			case pkgType
				when "Debian" then return pkgType
				when "RedHat" then return pkgType
				else raise ArgumentError, "Package type '#{pkgType}' is not programmed."
			end
		end

=begin
			uname usages:

			$ uname -i # Hardware platform
			x86_64
			$ uname -m # Machine
			x86_64
			$ uname -n # nodename, typically also $HOSTNAME.
			gifthorse
			$ uname -o # Operating System
			GNU/Linux
			$ uname -p # Processor
			x86_64
			$ uname -r # Kernel release
			3.11.0-15-generic
			$ uname -s # Kernel name
			Linux
			$ uname -v # Kernel version
			#25-Ubuntu SMP Thu Jan 30 17:22:01 UTC 2014
			$ uname -a
			Linux gifthorse 3.11.0-15-generic #25-Ubuntu SMP Thu Jan 30 17:22:01 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
=end

		def initialize(nameStr,pkgType,uNamedashp,uNamedasho)
			@Name			= nameStr
			@OSArch			= uNamedashp
			@OSType			= uNamedasho
			@PackageType	= validatePackageType(pkgType)

			@AuthLog		= @@AuthLog[@PackageType]
			@Dmesg			= @@Dmesg[@PackageType]
			@MailLog		= @@MailLog[@PackageType]
			@SysLog			= @@SysLog[@PackageType]

			freeze
		end

		def linuxEnoughMem(minMem)
			`free | grep -v total | awk '{print $4}'`.each_line do |no|
				unless no =~ /^\d+$/
					raise ArgumentError, "Programmer error with non integer '#{no}' for mem size."
				end
				return false if no.to_i < minMem
			end
			return true
		end

		def newVariation(riStr,cStr)
			return OS.new(@Name,@Arch,riStr,cStr);
		end

		def getPkgCmdPrefix
			case pkgType
				when "Debian" then "dpkg -i"
				when "RedHat" then "rpm -i --replacefiles"
			end
		end

	end

	class TestHost

		attr_reader :HostName, :IP, :OSO

		def validateTestIP(tIP)
			def validQuadword(qW)
				iqw = qW.to_i
				return true if 0 <= iqw && iqw <= 255
				return false
			end
			qwc = 0
			tIP.split('.').each do |qw|
				unless validQuadword(qw)
					raise ArgumentError, "Invalid quadword '#{qw}' in '#{tIP}'."
				end
				qwc += 1
			end
			unless qwc == 4
				raise ArgumentError, "Invalid quadword count of '#{qwc}' in '#{tIP}'."
			end
			return tIP
		end

		def initialize(ipStr,hnStr,osO,serviceManage=false)
			@IP				= validateTestIP(ipStr)
			@HostName		= hnStr
			@OSO			= osO
			@SMCmd			= serviceManage ? "service " : "/etc/init.d/"
			raise ArtumentError unless @IP =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
		end

		def getManageCmd(swStr,cmd)
			return "#{@SMCmd}#{cmdStr} #{cmd}"
		end

		def pingHostnameOrBlow
			pr = `ping -c 1 -w 2 #{@Hostname} | grep '1 received'`
			return if pr.length > 0
			raise IOError, "Unable to ping host '#{@IP}' (#{@HostName}?)"
		end

		def pingOrBlow
			pr = `ping -c 1 -w 2 #{@IP} | grep '1 received'`
			return if pr.length > 0
			raise IOError, "Unable to ping host '#{@IP}' (#{@HostName}?)"
		end

	end

	class TestAccess

		attr_reader :AdminUser, :HostO, :RTmpBDir, :TestUser

		def assureDate(rStr)
			to = Time.now
			rStr.chomp =~ /^\w{3} \w{3}\s+\d+\s+\d+:\d{2}:\d{2} \w{3} #{to.year}$/
		end

		def genPrefix(adminU=false)
			return "ssh #{@TestUser}@#{@HostO.IP}"	unless adminU
			return "ssh #{@AdminUser}@#{@HostO.IP}"		if adminU
		end

		def getOBPair(dSpec,fName)
			tmpcopy = "#{@RTmpBDir}/shwrap_#{fName}.copy"
			latest = "#{dSpec}/#{fName}"
			return tmpcopy, latest
		end

		def initialize(hO,admUser,testUser)
			@AdminUser	= admUser
			@HostO		= hO
			@TestUser	= testUser
			@RTmpBDir	= "/tmp"
			freeze
		end

		def cleanTmp(bName=nil)
			bfile = "shwrap_#{bName}*"	if bName
			bfile = "shwrap_*"		unless bName
			`ssh #{@AdminUser}@#{@HostO.IP} 'rm -f #{@RTmpBDir}#{bfile}'`
		end

		def cleanUpRemotes
			cmd = "kill -HUP \$(ps auxw | grep shwrap_ | awk \"{print \\$2}\" | grep -v PID)"
			hc = "ssh #{@AdminUser}@#{@HostO.IP} '#{cmd}'"
			`#{hc}`
		end

		def copyFile(dSpec,fName)
			tcopy, latest = getOBPair(dSpec,fName)
			hc = "ssh #{@AdminUser}@#{@HostO.IP} 'cp #{latest} #{tcopy}'"
			#puts "trace hc:  #{hc}"
			`#{hc}`
		end

		def diffAfter(dSpec,fName)
			tcopy, latest = getOBPair(dSpec,fName)
			hc = "ssh #{@AdminUser}@#{@HostO.IP} 'diff #{tcopy} #{latest} | grep \"^>\" | sed \"s\/> \/\/g\"'"
			`#{hc}`
		end

		def reCatRemote(bName,stdErr=false)
			bfile = "shwrap_#{bName}"
			bspec = "#{@RTmpBDir}/#{bfile}.stdout"	unless stdErr
			bspec = "#{@RTmpBDir}/#{bfile}.stderr"		if stdErr
			`ssh #{@AdminUser}@#{@HostO.IP} 'cat #{bspec}'`
		end

		def redirectRemote(cmdStr,bName)
			bfile = "shwrap_#{bName}"
			berr = "#{@RTmpBDir}/#{bfile}.stdout"
			bout = "#{@RTmpBDir}/#{bfile}.stderr"
			`ssh #{@AdminUser}@#{@HostO.IP} '#{cmdStr} >#{bout} 2>#{berr}'`
		end

		def sshTestAccountsOnHost
			adresult = `ssh #{@AdminUser}@#{@HostO.IP} date`
			unless assureDate(adresult)
				raise ArgumentError, "User #{@AdminUser} not reachable on #{@HostO.IP}."
			end
			tudresult = `ssh #{@TestUser}@#{@HostO.IP} date`
			unless assureDate(tudresult)
				raise ArgumentError, "User #{@TestUser} not reachable on #{@HostO.IP}."
			end
		end

		def sshTestUserOnHost
			cmd = "ssh #{@TestUser}@#{@HostO.IP} date"
			tudresult = `#{cmd}`
			unless assureDate(tudresult)
				raise ArgumentError, "User #{@TestUser} not reachable on #{@HostO.IP}."
			end
		end

		def shwrapCap(cmdStr,tuEx=true)
			u = tuEx ?  @TestUser : @AdminUser
			hc = "ssh #{u}@#{@HostO.IP} 'sudo #{cmdStr}'"	if tuEx == "sudo"
			hc = "ssh #{u}@#{@HostO.IP} '#{cmdStr}'"	unless tuEx == "sudo"
			#puts "trace hc:  #{hc}"
			Open3.capture3(hc)
		end

		def sudoTestUserToRootNoPasswd
			tusdresult = `ssh #{@TestUser}@#{@HostO.IP} sudo date`
			tusdudresult = `ssh #{@TestUser}@#{@HostO.IP} sudo -u #{@AdminUser} date`
			unless assureDate(tusdresult) and assureDate(tusdudresult)
				raise ArgumentError, "User #{@TestUser} not reachable on #{@HostO.IP}."
			end
		end

		def xtractTestEnvValue(envId,tuEx=true)
			so,se,st = shwrapCap("echo #{envId}",tuEx)
			return nil unless st == 0
			return so.chomp
		end

	end

	class BACommand

		attr_reader :AfterData, :BeforeData, :CmdStr, :Name, :Result

		def initialize(accO,nameStr,cmdStr)
			@AccO			= accO
			@AfterData		= nil
			@BeforeData		= @AccO.redirectRemote(cmdStr,nameStr)
			@CmdStr			= cmdStr
			@Name			= nameStr
		end

		def cleanUp
			@AccO.cleanTmp(@Name)
		end

		def finishMonitoring
			@AfterData = @AccO.redirectRemote(@CmdStr,@Name)
			freeze
		end

		def getStdErr
			@Acco.reCatRemote(@Name,true)
		end

		def getStdOut
			@Acco.reCatRemote(@Name)
		end

	end

	class BACMonitor

		attr_reader :Name

		def initialize(accO,nameStr,cmdStr)
			@AccO			= accO
			@CmdStr			= cmdStr
			@Name			= nameStr
			freeze
		end

		def newMono
			return BACommand.new(@AccO,@Name,@CmdStr)
		end

	end

	class DiffTail

		# Note when using this class, it is a good idea to re-initialize any logs before the beginning of your test,
		# as then you won't be risking pushing around very large files.  Sometimes a reboot will do this for syslog, for instance.
		attr_reader :DirSpec, :FileName, :Result

		def initialize(accO,dirSpec,fileName)
			@AccO			= accO
			@DirSpec		= dirSpec
			@FileName		= fileName
			@AccO.copyFile(@DirSpec,@FileName)
		end

		def cleanUp
			@AccO.cleanTmp(@Name)
		end

		def finishMonitoring
			@Result = @AccO.diffAfter(@DirSpec,@FileName)
			freeze
		end

		def getStdErr
			@Acco.reCatRemote(@FileName,true)
		end

		def getStdOut
			@Acco.reCatRemote(@FileName)
		end

	end

	class TailMonitor

		attr_reader :Name

		def initialize(accO,dSpec,fName)
			@AccO		= accO
			@DirSpec	= dSpec
			@FileName	= fName
			freeze
		end

		def newMono
			# Presuming this ThreadCmd object is for watching some environment aspect.
			return DiffTail.new(@AccO,@DirSpec,@FileName)
		end

	end

	class Tester

		attr_reader :AccO, :TestCmd, :MonOs, :Result, :Status, :StdErr, :TimeOutSeconds, :TimeOutStatus

		def initialize(accO,testCmd,monitorList,tuEx,timeOut)
			@AccO = accO
			@MResults = Hash.new
			@MonOs = Hash.new
			@TestCmd = testCmd
			@TimeOutSeconds = timeOut
			mtos = ( timeOut / 2.0 ).ceil
			monitorList.each do |mo|
				# Monitor objects are used as hash keys for:
				#	1.  Easy outside user access to thread objects.
				#	2.  Clear access from thread quiesce loop below.
				@MonOs[mo] = mo.newMono
			end
			@TimeOutStatus = Timeout::timeout(@TimeOutSeconds) {
				@Result, @StdErr, @Status = @AccO.shwrapCap(@TestCmd,tuEx)
			}
			@MonOs.keys.each do |mo|
				@MonOs[mo].finishMonitoring
			end
		end

	end

end # Shwrap module

# End of Shwrap.rb
