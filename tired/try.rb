#`ssh xeno@204.122.16.5 'ps | sed 's:PID:DIP:''`
#`ssh xeno@204.122.16.5 'ps'`
#r = `ssh xeno@shellx.eskimo.com ps`
#r = `ssh xeno@shellx.eskimo.com 'ps | sed "s/PID/DIP/"'`
#r = `ssh xeno@shellx.eskimo.com 'ps | sed 's/PID/DIP/''`
#r = `ssh xeno@shellx.eskimo.com "ps | awk \'{print \\$1}\'"`
#r = `ssh xeno@shellx.eskimo.com "ps | awk \'{print \\$1}\'"`
r = `ssh xeno@shellx.eskimo.com 'ps | awk "{print \\$1}"'`
puts r
