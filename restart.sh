#! /bin/sh


kill `cat daemons.rb.pid`
sudo kill `cat tmp/pids/server.pid`

# echo "Do you need to reset the database?"

# select yn in "Yes" "No"; do
# case $yn in
#     Yes ) rake db:drop && rake db:create && rake db:migrate && rake db:seed; break;;
#     No ) break;;
# esac
# done

# export NOTIF_CARITATHELP=`cat env/NOTIF_CARITATHELP`
# export SEND_MSG_CARITATHELP=`cat env/SEND_MSG_CARITATHELP`
# ruby websocket/server.rb
# rvmsudo -E rails s -b 172.31.31.97 -p 80 -d
