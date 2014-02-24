#!/bin/bash
#
#	tall.bash - Go through available test boxes.
#
################################################################################
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
tod=../data/to/$(date +%Y%m%d%H%M)
mkdir -p $(tod)
ruby user_test_shell_cmds.rb shellx.rb xeno $tod/shellx.stdout

for v in vub64v3 vde64v1
do

	# Probably need a different command for background:
	VBoxHeadless --startvm $v --vrde off &
	sleep 16

	ruby vbx_test_shell_cmds.rb $v xct >$tod/$v.stdout

	VBoxManage controlvm $v poweroff

done

if [[ -n $(ping -c 1 -s -w 2 hwloc1 2>/dev/null ) ]]
then
	ruby user_test_shell_cmds.rb hwloc1 xeno $tod/hwloc1.stdout
fi
#2345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
# End of tall.bash
