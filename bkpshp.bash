#!/bin/bash
#
# bkpshp.bash - Backup shwrap
#
fn=bkshop$(date +%Y%m%d%H%M).tgz
tar zcvf ~/cellar/$fn .
