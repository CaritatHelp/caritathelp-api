# -*- coding: utf-8 -*-
class MessagesController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_chatroom, except: [:index, :create, :reset]
  before_action :check_chatroom_rights, except: [:index, :create, :reset]
  
  api :POST, '/chatrooms', "Create a chatroom with the list of volunteers provided"
  param :token, String, "Your token", :required => true
  param :volunteers, ["1", "2", "..."], "Array of volunteers ids", :required => true
  example SampleJson.chatrooms('create')
  def create
    begin
      volunteers = chatroom_params[:volunteers]
      is_private = false

      if !volunteers.eql?(nil) and !volunteers.include?(@volunteer.id.to_s)
        volunteers.push @volunteer.id.to_s
      end

      # check if at least 2 people
      if volunteers.eql?(nil) or volunteers.count <= 1
        render :json => create_error(400, t("chatrooms.failure.min_two")) and return
      end

      # check if a private room between two people doesn't already exist
      if volunteers.count.eql?(2)
        is_private = true

        # need to find the correct query to avoid iterating through the chatrooms
        query = "SELECT chatrooms.id, chatrooms.name, chatrooms.number_volunteers, " +
          "(SELECT chatroom_volunteers.volunteer_id FROM chatroom_volunteers " +
          "WHERE chatroom_volunteers.chatroom_id=chatrooms.id AND " +
          "chatroom_volunteers.volunteer_id<>#{@volunteer.id.to_s})" +
          " AS participants FROM chatrooms WHERE chatrooms.is_private=true"

        # query = "SELECT chatrooms.id, chatrooms.name, chatrooms.number_volunteers, " +
        #   "chatrooms.number_messages, chatrooms.is_private FROM chatrooms " +
        #   "LEFT JOIN chatroom_volunteers link1 ON chatrooms.id=link1.chatroom_id AND " +
        #   "link1.volunteer_id=#{volunteers[0].to_s} " +
        #   "LEFT JOIN chatroom_volunteers link2 ON chatrooms.id=link2.chatroom_id AND " +
        #   "link2.volunteer_id=#{volunteers[1].to_s} GROUP BY chatrooms.id " +
        #   "WHERE chatrooms.is_private=true"

        # p "###"
        # p volunteers
        # p "###"
        exist_chatroom = ActiveRecord::Base.connection.execute(query)

        # unless exist_chatroom.eql?(nil) or exist_chatroom.first.eql?(nil)
        #   render :json => create_response(exist_chatroom.first) and return
        # end

        unless exist_chatroom.eql?(nil)
          exist_chatroom.each do |chatroom|
            if chatroom['participants'].eql?(volunteers[0])
              render :json => create_response(chatroom) and return
            end
          end
        end

      end

      new_chatroom = Chatroom.new({
                                    name: params[:name],
                                    number_volunteers: volunteers.count,
                                    number_messages: 0,
                                    is_private: is_private
                                  })
      new_chatroom.save!

      volunteers.each do |id|
        ChatroomVolunteer.create!([chatroom_id: new_chatroom.id, volunteer_id: id])
      end

      render :json => create_response(new_chatroom) and return
    rescue => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :GET, '/chatrooms', "Get volunteer's chatrooms ordered by date of last message"
  param :token, String, "Your token", :required => true
  example SampleJson.chatrooms('index')
  def index
    # on liste toutes les chatroom d'un user, trié en fonction de la date du dernier
    # message present dedans
    # pour chaque, il faudrait la liste des volunteers qui sont dedans...
    query = "chatrooms.id, chatrooms.name, chatrooms.number_volunteers, chatrooms.number_messages"

    render :json => create_response(Chatroom.joins(:chatroom_volunteers)
                                      .where(:chatroom_volunteers => { volunteer_id: @volunteer.id })
                                      .order(updated_at: :desc)
                                      .select(query))
  end

  api :GET, '/chatrooms/:id/volunteers', "Get the list of chatroom's volunteers"
  param :token, String, "Your token", :required => true
  example SampleJson.chatrooms('participants')
  def participants
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.thumb_path"
    render :json => create_response(Volunteer.joins(:chatroom_volunteers)
                                      .where(chatroom_volunteers: { chatroom_id: @chatroom.id })
                                      .select(query))
  end

  api :GET, '/chatrooms/:id', "Get messages of the chatroom, ordered by date"
  param :token, String, "Your token", :required => true
  example SampleJson.chatrooms('show')
  def show
    # modifier pour renvoyer le nom et l'id de l'envoyeur pour chaque message
    render :json => create_response(Message.where(:chatroom_id => @chatroom.id)
                                      .order(created_at: :asc))
  end

  api :PUT, '/chatrooms/:id/set_name', "Set the name of the chatroom"
  param :token, String, "Your token", :required => true
  param :name, String, "New name to give to the chatroom", :required => true
  example SampleJson.chatrooms('set_name')
  def set_name
    begin
      @chatroom.name = params[:name]
      @chatroom.save!
      render :json => create_response(@chatroom) and return
    rescue => e
      render :json => create_error(400, e.to_s) and return      
    end
  end

  api :PUT, '/chatrooms/:id/add_volunteers', "Add volunteers referred by ids to the chatroom"
  param :token, String, "Your token", :required => true
  param :volunteers, ["1", "2", "..."], "Array of volunteers ids", :required => true
  example SampleJson.chatrooms('add_volunteers')
  def add_volunteers
    begin
      # avoid adding on is_private chatroom ?

      volunteers = params[:volunteers]
      names = []

      volunteers.each do |id|
        # check if the volunteer is not already in the chatroom
        if ChatroomVolunteer.where(chatroom_id: @chatroom.id).where(volunteer_id: id).first.eql?(nil)
          ChatroomVolunteer.create!([chatroom_id: @chatroom.id, volunteer_id: id])
          current_volunteer = Volunteer.find(id)
          names.push current_volunteer[:firstname]
        end
      end

      # increment the total number of participants in the chatroom
      @chatroom.number_volunteers += names.count
      @chatroom.is_private = false
      @chatroom.save!

      render :json => create_response(names) and return
    rescue => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :PUT, '/chatrooms/:id/new_message', "Add a message to the chatroom"
  param :token, String, "Your token", :required => true
  param :content, String, "Content of the message", :required => true
  example SampleJson.chatrooms('new_message')
  def new_message
    begin
      message = Message.create!([
                                 :content => params[:content],
                                 :volunteer_id => @volunteer.id,
                                 :chatroom_id => @chatroom.id
                                ])
      @chatroom.number_messages += 1
      @chatroom.save!

      send_msg_to_socket(message, @chatroom.id, @volunteer)

      render :json => create_response(message)
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  api :DELETE, '/chatrooms/:id/kick', "Kick a volunteer from the chatroom"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of the volunteer to kick", :required => true
  example SampleJson.chatrooms('kick_volunteer')
  def kick_volunteer
    begin
      link = ChatroomVolunteer.where(:chatroom_id => @chatroom.id)
        .where(:volunteer_id => params[:volunteer_id]).first
      
      unless link.eql?(nil)
        link.destroy

        @chatroom.number_volunteers -= 1
        @chatroom.save!

        render :json => create_response(t("chatrooms.success.kicked")) and return
      end
      render :json => create_error(400, t("chatrooms.failure.not_found"))
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  api :DELETE, '/chatrooms/:id/leave', "Leave the chatroom"
  param :token, String, "Your token", :required => true
  example SampleJson.chatrooms('leave')
  def leave
    begin
      @link.destroy

      if @chatroom.number_volunteers.eql?(1)
        @chatroom.destroy
      else
        @chatroom.number_volunteers -= 1
        @chatroom.save!
      end
      
      render :json => create_response(t("chatrooms.success.leave"))
    rescue => e
      render :json => create_error(400, e.to_s)
    end    
  end

  api :DELETE, '/chatrooms/:id/delete_message', "Delete a message of the chatroom"
  param :token, String, "Your token", :required => true
  param :message_id, String, "Id of the message to delete", :required => true
  example SampleJson.chatrooms('delete_message')
  def delete_message
    begin
      message = Message.find(params[:message_id])

      if message.volunteer_id.eql?(@volunteer.id)
        message.destroy
        
        @chatroom.number_messages -= 1
        @chatroom.save!
        
        render :json => create_response(t("messages.success.deleted")) and return
      end
      render :json => create_error(400, t("messages.failure.rights"))
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  private
  def chatroom_params
    params.permit(:name, :volunteers => [])
  end

  def set_volunteer
    @volunteer = Volunteer.find_by(token: params[:token])
  end

  def set_chatroom
    begin
      @chatroom = Chatroom.find(params[:id])
    rescue
      render :json => create_error(400, t("chatrooms.failure.id"))
    end
  end

  def check_chatroom_rights
    @link = ChatroomVolunteer.where(volunteer_id: @volunteer.id)
      .where(chatroom_id: @chatroom.id).first
    if @link.eql?(nil)
      render :json => create_error(400, t("chatrooms.failure.rights")) and return      
    end
  end

  def send_msg_to_socket(message, chatroom_id, volunteer)
    begin
      concerned_volunteers = Volunteer.joins(:chatroom_volunteers)
        .where(chatroom_volunteers: { chatroom_id: chatroom_id })
        .select("volunteers.id, volunteers.token").all

      json_msg = {
        token: ENV['SEND_MSG_CARITATHELP'],
        chatroom_id: chatroom_id,
        sender_firstname: volunteer.firstname,
        sender_lastname: volunteer.lastname,
        content: message[0]['content'],
        concerned_volunteers: concerned_volunteers
      }.to_json

      WebSocket::Client::Simple.connect("ws://" + Rails.application.config.ip + ":" +
                                        Rails.application.config.port_websocket.to_s) do |ws|
        ws.on :open do
          ws.send(json_msg)
          ws.close
        end
      end
    rescue
    end
  end
end
