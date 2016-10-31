class MessagesController < ApplicationController
  swagger_controller :messages, "Messages management"

  before_action :authenticate_volunteer!, unless: :is_swagger_request?
  
  before_action :set_chatroom, except: [:index, :create, :reset]
  before_action :check_chatroom_rights, except: [:index, :create, :reset]
  
  swagger_api :create do
    summary "Create a chatroom with the list of volunteers provided"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :name, :string, :optional, "Chatroom's name"
    param :form, 'volunteers[]', :string, :required, "Volunteers' ids"
    response :ok
  end
  def create
    begin
      volunteers = []
      volunteers_params = chatroom_params[:volunteers]
      is_private = false
      
      # handle passing params has volunteers[]=[1, 2, 3] and volunteers[]=1&volunteers[]=2
      # cannot JSON.parse a string of length <= 1
      if volunteers_params.count == 1 and is_valid_json?(volunteers_params.first)
        volunteers_params = JSON.parse(volunteers_params.first)
      end
      
      volunteers_params.each do |volunteer_id|
        volunteer_to_add = Volunteer.find_by(id: volunteer_id.to_i)
        
        if volunteer_to_add.blank?
          render :json => create_error(400, t("chatrooms.failure.unknown_volunteer_id")) and return
        end
        volunteers.push volunteer_to_add
      end
      
      volunteers.push(current_volunteer) unless volunteers.include?(current_volunteer)

      if volunteers.count < 2
        render :json => create_error(400, t("chatrooms.failure.min_two")) and return
      end

      if volunteers.count == 2
        is_private = true

        other_volunteer = volunteers.first
        other_volunteer = volunteers.second if other_volunteer == current_volunteer
        existing_chatroom = current_volunteer.chatrooms.select { |chatroom| chatroom.number_volunteers == 2 and chatroom.volunteers.find_by(id: other_volunteer) }
        render json: create_response(existing_chatroom.first) and return if existing_chatroom.present?
      end

      new_chatroom = Chatroom.new(name: params[:name],
                                  number_volunteers: volunteers.count,
                                  number_messages: 0,
                                  is_private: is_private)

      if new_chatroom.save
        volunteers.each do |volunteer|
          ChatroomVolunteer.create!(chatroom_id: new_chatroom.id, volunteer_id: volunteer.id)
        end
        render :json => create_response(new_chatroom) and return
      else
        render :json => create_error(400, new_chatroom.errors) and return
      end
    rescue => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :index do
    summary "Get volunteer's chatrooms ordered by date of last message"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def index
    render json: create_response(current_volunteer.chatrooms.order(updated_at: :desc).map { |chatroom| chatroom.attributes.merge(volunteers: chatroom.volunteers.map(&:fullname), read: chatroom.read_by?(current_volunteer)) })
  end

  swagger_api :participants do
    summary "Get the list of chatroom's volunteers"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def participants
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.thumb_path"
    render :json => create_response(Volunteer.joins(:chatroom_volunteers)
                                      .where(chatroom_volunteers: { chatroom_id: @chatroom.id })
                                      .select(query))
  end

  swagger_api :show do
    summary "Get messages of the chatroom, ordered by date"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def show
    messages = Message
               .select("messages.*")
               .select("(SELECT volunteers.fullname FROM volunteers WHERE volunteers.id=messages.volunteer_id)")
               .select("(SELECT volunteers.thumb_path thumb_path FROM volunteers WHERE volunteers.id=messages.volunteer_id)")
               .where(chatroom_id: @chatroom.id)
               .order(created_at: :asc)

    @chatroom.set_as_read_by current_volunteer

    render :json => create_response(messages)
  end

  swagger_api :set_name do
    summary "Set chatroom's name"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :form, :name, :string, :required, "Chatroom's new name"
    response :ok
  end
  def set_name
    begin
      @chatroom.name = params[:name]
      @chatroom.save!
      render :json => create_response(@chatroom) and return
    rescue => e
      render :json => create_error(400, e.to_s) and return      
    end
  end

  swagger_api :update do
    summary "Add volunteers to the chatroom and/or rename it"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :form, 'volunteers[]', :string, :optional, "Volunteers' ids to add"
    param :form, 'name', :string, :optional, "Chatroom's new name"
    response :ok
  end
  def update
    begin
      if params[:name].present?
        @chatroom.name = params[:name]
      end

      if params[:volunteers].present?
        volunteers_params = params[:volunteers]
        
        # handle passing params has volunteers[]=[1, 2, 3] and volunteers[]=1&volunteers[]=2
        # cannot JSON.parse a string of length <= 1
        if volunteers_params.count == 1 and is_valid_json?(volunteers_params.first)
          volunteers_params = JSON.parse(volunteers_params.first)
        end

        volunteers_params.each do |volunteer_id|
          # check if the volunteer is not already in the chatroom
          volunteer_to_add = Volunteer.find_by(id: volunteer_id.to_i)          
          
          if volunteer_to_add.blank?
            render :json => create_error(400, t("chatrooms.failure.unknown_volunteer_id")) and return
          end
          
          unless @chatroom.volunteers.include?(volunteer_to_add)
            @chatroom.chatroom_volunteers.build(volunteer: volunteer_to_add)
            @chatroom.number_volunteers += 1
          end
        end
        
        @chatroom.is_private = false
      end

      @chatroom.save!

      render :json => create_response(@chatroom.attributes.merge(volunteers: @chatroom.volunteers.map(&:fullname))) and return
    rescue => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :new_message do
    summary "Write a message to the chatroom"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :content, :string, :required, "Message's content"
    response :ok
  end
  def new_message
    begin
      message = Message.create!(:content => params[:content],
                                :volunteer_id => current_volunteer.id,
                                :chatroom_id => @chatroom.id)
      @chatroom.set_as_unread
      @chatroom.set_as_read_by current_volunteer
      @chatroom.number_messages += 1
      @chatroom.save!

      send_msg_to_socket(message, @chatroom.id, current_volunteer)

      render :json => create_response(message.attributes
                                       .merge(fullname: current_volunteer.fullname))
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  swagger_api :kick_volunteer do
    summary "Kick volunteer from the chatroom"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :volunteer_id, :integer, :required, "Volunteer's id"
    response :ok
  end
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

  swagger_api :leave do
    summary "Leave the chatroom"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
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

  swagger_api :delete_message do
    summary "Delete message from the chatroom"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :message_id, :integer, :required, "Message's id"
    response :ok
  end
  def delete_message
    begin
      message = Message.find(params[:message_id])

      if message.volunteer_id.eql?(current_volunteer.id)
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

  def set_chatroom
    begin
      @chatroom = Chatroom.find(params[:id])
    rescue
      render :json => create_error(400, t("chatrooms.failure.id"))
    end
  end

  def check_chatroom_rights
    @link = ChatroomVolunteer.where(volunteer_id: current_volunteer.id)
      .where(chatroom_id: @chatroom.id).first
    if @link.eql?(nil)
      render :json => create_error(400, t("chatrooms.failure.rights")) and return      
    end
  end

  def send_msg_to_socket(message, chatroom_id, volunteer)
    begin
      concerned_volunteers = Volunteer.joins(:chatroom_volunteers)
        .where(chatroom_volunteers: { chatroom_id: chatroom_id })
        .select("volunteers.id, volunteers.uid").all
      
      json_msg = {
        token: ENV['SEND_MSG_CARITATHELP'],
        chatroom_id: chatroom_id,
        sender_id: volunteer.id,
        sender_firstname: volunteer.firstname,
        sender_lastname: volunteer.lastname,
        sender_thumb_path: volunteer.thumb_path,
        content: message['content'],
        created_at: message['created_at'],
        concerned_volunteers: concerned_volunteers
      }.to_json

      WebSocket::Client::Simple.connect("ws://" + Rails.application.config.ip) do |ws|
        ws.on :open do
          ws.send(json_msg)
          ws.close
        end
      end
    rescue => e
      p e
    end
  end

  def is_valid_json?(str)
    begin
      JSON.parse(str)
      return true
    rescue JSON::ParserError => e
      return false
    end
  end
end
