require 'em-websocket'
require 'pg'
require 'daemons'
require 'json'

Daemons.daemonize

sEND_MSG_CARITATHELP = "MCJORR982-ZJHFfe541wxcvbpoizin23231598765185479531dezrjnjhjkae94g41zz4r8g416g5t4eg6io4iop4lkyy4zzefdf"
nOTIF_CARITATHELP = "JDEje9578efr9zeUPAMD65"

@tokens_types = {
  sEND_MSG_CARITATHELP => 'message',
  nOTIF_CARITATHELP => 'notification'
}

@channels_list = Hash.new

EventMachine.run do

  EventMachine::WebSocket.start(host: "172.31.31.97", port: 8080, debug: true) do |ws|
    ws.onopen do      
      begin
        current_user_token = nil
        @channel = EM::Channel.new
        
        sid = @channel.subscribe { |msg|
          begin
            ws.send(msg)
          rescue => e
            p "On subscribe: " + e.message.to_s
          end
        }

        ws.onmessage { |msg|
          begin
            json_msg = JSON.parse(msg)
            
            if json_msg['token'].eql?('token')
              if current_user_token.eql?(nil)
                current_user_token = json_msg['token_user']
                @channels_list[current_user_token] = @channel
              end
              
            elsif @tokens_types.key?(json_msg['token'])
              json_msg['type'] = @tokens_types[json_msg['token']]
              
              concerned_volunteers = json_msg['concerned_volunteers']            
              json_msg.delete('concerned_volunteers')
              json_msg.delete('token')
              
              if concerned_volunteers != nil and concerned_volunteers.count > 0
                concerned_volunteers.each do |volunteer|
                  if @channels_list[volunteer['token']] != nil
                    @channels_list[volunteer['token']]
                      .push(json_msg.to_json)
                  end
                end
              end
            end
          rescue => e
            p "On send: " + e.message.to_s
          end
        }
        
        ws.onclose {
          # unsubsribe the disconnected user from the channel
          # delete the channel from the channels_list
          begin
            @channels_list.delete(current_user_token).unsubscribe(sid)
          rescue => e
            p "On close:" + e.message.to_s
          end
        }
      rescue => e
        p e.message.to_s
      end      
    end
  end
end
