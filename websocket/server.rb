require 'em-websocket'
require 'pg'

@channels_list = Hash.new

EventMachine.run do

  EventMachine::WebSocket.start(host: "0.0.0.0", port: 8080, debug: true) do |ws|
    ws.onopen do      
      begin
        connection = nil
        current_user = nil
        @channel = EM::Channel.new
        
        sid = @channel.subscribe { |msg| ws.send(msg) }        

        ws.onmessage { |msg|

          array = msg.split

          # if the received msg start by SEND_MSG_KOOLVIS key
          # it means the client already connected before
          # next word should be the id of the targeted chatroom
          # after that should be the content of the message
          if array[0].eql?(ENV['SEND_MSG_CARITATHELP'])
            if connection.eql? nil
              connection = PG.connect :dbname => 'pg_test_development',
              :user => 'robin',
              :password => 'root'
            end

            array.shift
            chatroom_id = array.shift
            
            # get the list of user participants to the targeted chatroom
            query = "SELECT chatroom_volunteers.volunteer_id FROM chatroom_volunteers " +
              "WHERE chatroom_volunteers.chatroom_id=#{chatroom_id}"
            users_list = connection.exec(query)
            
            if users_list != nil and users_list.count > 0
              # send the message in the channel of each participant
              users_list.each do |user|
                if @channels_list[user['volunteer_id']] != nil
                  @channels_list[user['volunteer_id']]
                    .push(chatroom_id + " " + array.join(' '))
                end
              end
            end

            # if the received msg start by NOTIF_KOOLVIS key
            # it means the client already connected before
            # the second word should be the id of the notification
            # the second word should be the type of the notification
            # the third word should be the name from where comes the notification
            # can be Firstname/Lastname, Event name or Assoc name
          elsif array[0].eql?(ENV['NOTIF_CARITATHELP'])
            if connection.eql? nil
              connection = PG.connect :dbname => 'pg_test_development',
              :user => 'robin',
              :password => 'root'
            end

            # depop NOTIF_CARITATHELP
            array.shift
            # depop id of notification
            notif_id = array.shift
            
            # request to get the notification from db
            query = "SELECT * FROM notifications WHERE notifications.id=#{notif_id}"
            notification = connection.exec(query)[0]

            id = nil
            name = nil
            concerned_event_or_assoc_id = ""
            # get the id and the name of :
            #   - Event if it's an event who is inviting someone
            #   - Assoc if it's an asso who is inviting someone
            #   - Volunteer for all other cases (add friend, join assoc and join event)
            if notification['event_id'] != nil and notification['receiver_id'] != nil
              id = notification['event_id']
              query = "SELECT events.id, events.title FROM events WHERE events.id=#{notification['event_id']}"
              event = connection.exec(query)[0]
              name = event['title']
            elsif notification['assoc_id'] != nil and notification['receiver_id'] != nil
              id = notification['assoc_id']
              query = "SELECT assocs.id, assocs.name FROM assocs WHERE assocs.id=#{notification['assoc_id']}"
              assoc = connection.exec(query)[0]
              name = assoc['name']
            else
              id = notification['sender_id']
              query = "SELECT * FROM volunteers WHERE volunteers.id=#{notification['sender_id']}"
              volunteer = connection.exec(query)[0]
              name = volunteer['firstname'] + " " + volunteer['lastname']
              if notification['assoc_id'] != nil
                concerned_event_or_assoc_id = notification['assoc_id']
              elsif notification['event_id'] != nil
                concerned_event_or_assoc_id = notification['event_id']
              end
            end

            # if there is no receiver_id in the notif, it means the notif is destined to several volunteers (admin/owners..)
            # so we get the links between volunteers and this notifications and send it to all of them
            if notification['receiver_id'].eql?(nil)
              query = "SELECT * FROM notification_volunteers WHERE notification_volunteers.notification_id=#{notif_id}"
              links = connection.exec(query)
              
              links.each do |link|
                if @channels_list[link['volunteer_id']] != nil
                  @channels_list[link['volunteer_id']].push("notif " + notification['notif_type'] + " " + concerned_event_or_assoc_id + " " + name + " " + id)                  
                end
              end

              # if there is a receiver_id, it means there is only on recipient for this notif, so we simply send it to him
            else
              if @channels_list[notification['receiver_id']] != nil
                @channels_list[notification['receiver_id']].push("notif " + notification['notif_type'] + " " + name + " " + id)
              end
            end


            # if the received msg start by token it means the client is connecting
            # and the next word should be the token
          elsif array[0].eql?('token')
            if connection.eql? nil
              connection = PG.connect :dbname => 'pg_test_development',
              :user => 'robin',
              :password => 'root'
            end
            
            # on connection, get the user refered by the provided token
            if current_user.eql? nil 
              begin
                current_user = connection.exec("SELECT * FROM volunteers WHERE token='#{array[1]}'")
                @channels_list[current_user[0]['id']] = @channel
              rescue => e
                e.message.to_s
              end
            end
            
          end
        }
        
        ws.onclose {
          # unsubsribe the disconnected user from the channel
          # delete the channel from the channels_list
          begin
            @channels_list.delete(current_user[0]['id']).unsubscribe(sid)
          rescue => e
            e.message.to_s
          end
        }
      rescue => e
        p e.message.to_s
      ensure
        connection.close if connection
      end      
    end
  end
end
