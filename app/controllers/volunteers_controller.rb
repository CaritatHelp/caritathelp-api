class VolunteersController < ApplicationController
  swagger_controller :volunteers, "Volunteers management"

  before_action :authenticate_volunteer!, unless: :is_swagger_request?

  skip_before_filter :verify_authenticity_token, :only => [:destroy]
  before_action :set_volunteer, only: [:show, :edit, :destroy, :friends, :associations, :events, :pictures, :main_picture, :news]

  swagger_api :index do
    summary "Get a list of all volunteers"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def index
    query = "SELECT volunteers.id, email, firstname, lastname, birthday, gender, " +
      "city, latitude, longitude, allowgps, allow_notifications, thumb_path, " +
      "(SELECT COUNT(*) FROM v_friends AS link INNER JOIN v_friends " +
      "ON link.friend_volunteer_id=v_friends.friend_volunteer_id WHERE " +
      "link.volunteer_id=#{current_volunteer.id} AND " +
      "v_friends.volunteer_id=volunteers.id AND " +
      "v_friends.volunteer_id<>#{current_volunteer.id}) AS nb_common_friends FROM volunteers"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  swagger_api :show do
    summary "Get volunteer's profile"
    param :path, :id, :integer, :required, "Volunteer's id to show"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def show
    begin

      if current_volunteer.id == @volunteer.id
        render :json => create_response(@volunteer.as_json(:except => [:password])
                                          .merge('friendship' => 'yourself')) and return
      end

      friendship = nil
      notif_id = nil

      link = VFriend
        .where(:volunteer_id => @volunteer.id)
        .where(:friend_volunteer_id => current_volunteer.id).first

      if link.eql?(nil)
        link = Notification.where(notif_type: 'AddFriend')
          .where(sender_id: current_volunteer.id)
          .where(receiver_id: @volunteer.id)
          .first
        if link.eql?(nil)
          link = Notification.where(notif_type: 'AddFriend')
            .where(receiver_id: current_volunteer.id)
            .where(sender_id: @volunteer.id)
            .first
          if !link.eql?(nil)
            friendship = 'invitation received'
            notif_id = link.id
          end
        else
          friendship = 'invitation sent'
          notif_id = link.id
        end
      else
        friendship = 'friend'
      end

      render :json => create_response(@volunteer.as_json(:except => [:password])
                                        .merge(friendship: friendship,
                                               notif_id: notif_id)) and return
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  swagger_api :search do
    summary "Search for volunteers, returns a list of volunteers"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :research, :string, :required, "Volunteer's firstname/lastname"
    response :ok
  end
  def search
    begin
      words = params[:research].downcase.split(/\W+/)

      if words.size > 0
        condition = "lower(name) LIKE '%#{words[0]}%'"

        words.drop(1).each do |word|
          condition += " AND lower(name) LIKE '%#{word}%'"
        end

        assocs = Assoc
          .select(:id, :name, :thumb_path,
                  "(SELECT rights FROM av_links WHERE av_links.assoc_id=assocs.id AND av_links.volunteer_id=#{current_volunteer.id}) AS rights", "'assoc' AS result_type")
          .where(condition)

        condition = condition.gsub "name", "title"
        events = Event
          .select(:id, 'title AS name', :thumb_path,
                  "(SELECT rights FROM event_volunteers WHERE event_volunteers.event_id=events.id AND event_volunteers.volunteer_id=#{current_volunteer.id}) AS rights", "'event' AS result_type")
          .where(condition)


        condition = condition.gsub "title", "fullname"
        volunteers = Volunteer
          .select(:id, 'fullname AS name', :thumb_path,
                  "(SELECT COUNT(*) FROM v_friends WHERE v_friends.volunteer_id=volunteers.id AND v_friends.friend_volunteer_id=#{current_volunteer.id}) AS rights", "'volunteer' AS result_type")
          .where(condition)

        result = (assocs + events + volunteers).sort {|a,b| a['name']<=>b['name']}

        render :json => create_response(result) and return
      end

      render :json => create_error(400, t("volunteers.failure.research"))
    rescue => e
      render :json => create_error(400, t("volunteers.failure.research"))
    end
  end

  swagger_api :notifications do
    summary "Get volunteer's notifications"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def notifications
    n1 = Notification.select { |notification| notification.receiver_id == current_volunteer.id }
    n2 = NotificationVolunteer.select { |link| link.volunteer_id == current_volunteer.id }
         .map { |link| link.notification }
    render json: create_response((n1 + n2).sort { |a, b| b.created_at <=> a.created_at })
  end

  swagger_api :friends do
    summary "Get volunteer's friends list"
    param :path, :id, :integer, :required, "Volunteer's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def friends
    query = "SELECT volunteers.id, email, firstname, lastname, birthday, gender, " +
      "city, latitude, longitude, allowgps, allow_notifications, thumb_path, fullname, " +
      "(SELECT COUNT(*) FROM v_friends AS link INNER JOIN v_friends " +
      "ON link.friend_volunteer_id=v_friends.friend_volunteer_id WHERE " +
      "link.volunteer_id=#{@volunteer.id} AND " +
      "v_friends.volunteer_id=volunteers.id AND " +
      "v_friends.volunteer_id<>#{@volunteer.id}) AS nb_common_friends FROM volunteers " +
      "INNER JOIN v_friends ON volunteers.id=v_friends.friend_volunteer_id WHERE v_friends.volunteer_id=#{@volunteer.id}"
    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  swagger_api :associations do
    summary "Get volunteer's associations list"
    param :path, :id, :integer, :required, "Volunteer's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def associations
    query = "SELECT assocs.id, assocs.name, assocs.city, assocs.thumb_path, av_links.rights, " +
      "(SELECT COUNT(*) FROM av_links WHERE av_links.assoc_id=assocs.id) AS nb_members, " +
      "(SELECT COUNT(*) FROM av_links INNER JOIN v_friends ON " +
      "av_links.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE assoc_id=assocs.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members" +
      " FROM assocs INNER JOIN av_links ON av_links.assoc_id=assocs.id " +
      "WHERE av_links.volunteer_id=#{@volunteer.id}"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  swagger_api :events do
    summary "Get volunteer's events list"
    param :path, :id, :integer, :required, "Volunteer's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def events
    query = "SELECT events.id, events.title, events.place, events.begin, events.end, " +
      "events.assoc_id, events.assoc_name, events.thumb_path, event_volunteers.rights, " +
      "(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest, " +
      "(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON " +
      "event_volunteers.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members" +
      " FROM events INNER JOIN event_volunteers ON event_volunteers.event_id=events.id " +
      "WHERE event_volunteers.volunteer_id=#{@volunteer.id}"

    range = params[:range]

    if range.eql?('past')
      query += " AND events.end < NOW()"
    elsif range.eql?('current')
      query += " AND events.begin < NOW() AND events.end > NOW()"
    elsif range.eql?('futur')
      query += " AND events.begin > NOW()"
    end

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  swagger_api :friend_requests do
    summary "Returns a list of all pendinf friends' invitations"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :sent, :boolean, :optional, "true: invitations sent. false: invitations received."
    response :ok
  end
  def friend_requests
    volunteers = nil
    if params[:sent].eql?('true')
	    notifications = Notification.select { |n| n.is_friend_invitation? and n.sender_id == current_volunteer.id }
  	  volunteers = notifications.map { |n| Volunteer.select(:id, :firstname, :lastname, :fullname, :thumb_path).find(n.receiver_id).as_json.merge(notif_id: n.id) }
    else
	    notifications = Notification.select { |n| n.is_friend_invitation? and n.receiver_id == current_volunteer.id }
  	  volunteers = notifications.map { |n| Volunteer.select(:id, :firstname, :lastname, :fullname, :thumb_path).find(n.sender_id).as_json.merge(notif_id: n.id) }
    end

    render :json => create_response(volunteers)
  end

  swagger_api :pictures do
    summary "Returns a list of all volunteer's pictures path"
    param :path, :id, :integer, :required, "Volunteer's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def pictures
    query = "id, file_size, picture_path, is_main"
    pictures = Picture.where(:volunteer_id => @volunteer.id)
      .where(:event_id => nil).where(:assoc_id => nil).select(query).limit(100)
    render :json => create_response(pictures)
  end

  swagger_api :main_picture do
    summary "Returns path of main picture"
    param :path, :id, :integer, :required, "Volunteer's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def main_picture
    query = "id, file_size, picture_path"
    pictures = Picture.where(:volunteer_id => @volunteer.id)
      .where(:event_id => nil).where(:assoc_id => nil).where(:is_main => true)
      .select(query).first
    render :json => create_response(pictures)
  end

  swagger_api :news do
    summary "Get volunteer's news"
    param :path, :id, :integer, :required, "Volunteer's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def news
    link = current_volunteer.v_friends.find_by(friend_volunteer_id: @volunteer.id)
    render json: create_response(@volunteer.news.select { |new| (new.private and link.present?) or new.public })
  end

  private
  def set_volunteer
    begin
      @volunteer = Volunteer.find(params[:id])
    rescue
      render :json => create_error(400, t("volunteers.failure.id"))
      return
    end
  end

  def volunteer_params
    params.permit(:email, :password, :firstname, :lastname,
                  :birthday, :gender, :city, :latitude, :longitude,
                  :allowgps)
  end
end
