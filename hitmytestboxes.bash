#!/bin/bash
#
#	Go through available test boxes.
#
ruby user_test_shell_cmds.rb shellx.rb xeno ../data/shellx.test_results.$(date +%Y%m%d%H%M)

for v in vub64v3 vde64v1
do

	# Probably need a different command for background:
	VBoxHeadless --startvm $v --vrde off &
	sleep 16

	ruby vbx_test_shell_cmds.rb $v xct >$v.test_results.$(date +%Y%m%d%H%M)

	VBoxManage controlvm $v poweroff

done
