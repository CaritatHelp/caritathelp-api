#! /bin/sh

kill `cat daemons.rb.pid`
sudo kill `cat tmp/pids/server.pid`
export NOTIF_CARITATHELP=`cat NOTIF_CARITATHELP`
export SEND_MSG_CARITATHELP=`cat SEND_MSG_CARITATHELP`
ruby websocket/server.rb
rvmsudo -E rails s -b 172.31.31.97 -p 80 -d
