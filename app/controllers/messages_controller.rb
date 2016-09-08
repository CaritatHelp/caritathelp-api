class MessagesController < ApplicationController
  swagger_controller :messages, "Messages management"

  before_filter :check_token
  before_action :set_volunteer
  before_action :set_chatroom, except: [:index, :create, :reset]
  before_action :check_chatroom_rights, except: [:index, :create, :reset]
  
  swagger_api :create do
    summary "Create a chatroom with the list of volunteers provided"
    param :query, :token, :string, :required, "Your token"
    param :query, :name, :string, :optional, "Chatroom's name"
    param :form, 'volunteers[]', :string, :required, "Volunteers' ids"
    response :ok
  end
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

  swagger_api :index do
    summary "Get volunteer's chatrooms ordered by date of last message"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def index
      render json: create_response(@volunteer.chatrooms.order(updated_at: :desc).map { |chatroom| chatroom.attributes.merge(volunteers: chatroom.volunteers.map(&:fullname)) })
  end

  swagger_api :participants do
    summary "Get the list of chatroom's volunteers"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :query, :token, :string, :required, "Your token"
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
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def show
    messages = Message
               .select("messages.*")
               .select("(SELECT volunteers.fullname FROM volunteers WHERE volunteers.id=messages.volunteer_id)")
               .select("(SELECT volunteers.thumb_path thumb_path FROM volunteers WHERE volunteers.id=messages.volunteer_id)")
               .where(chatroom_id: @chatroom.id)
               .order(created_at: :asc)

    render :json => create_response(messages)
  end

  swagger_api :set_name do
    summary "Set chatroom's name"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :query, :token, :string, :required, "Your token"
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

  swagger_api :add_volunteers do
    summary "Add volunteers to the chatroom"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :query, :token, :string, :required, "Your token"
    param :form, 'volunteers[]', :string, :required, "Volunteers' ids to add"
    response :ok
  end
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

  swagger_api :new_message do
    summary "Write a message to the chatroom"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :query, :token, :string, :required, "Your token"
    param :query, :content, :string, :required, "Message's content"
    response :ok
  end
  def new_message
    begin
      message = Message.create!(:content => params[:content],
                                :volunteer_id => @volunteer.id,
                                :chatroom_id => @chatroom.id)
      @chatroom.number_messages += 1
      @chatroom.save!

      send_msg_to_socket(message, @chatroom.id, @volunteer)

      render :json => create_response(message)
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  swagger_api :kick_volunteer do
    summary "Kick volunteer from the chatroom"
    param :path, :id, :integer, :required, "Chatroom's id"
    param :query, :token, :string, :required, "Your token"
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
    param :query, :token, :string, :required, "Your token"
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
    param :query, :token, :string, :required, "Your token"
    param :query, :message_id, :integer, :required, "Message's id"
    response :ok
  end
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
        content: message['content'],
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
