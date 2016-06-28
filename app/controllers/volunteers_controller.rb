class VolunteersController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:create, :destroy]
  before_filter :check_token, except: [:create, :destroy]
  before_action :set_volunteer, only: [:show, :edit, :update, :destroy, :friends, :notifications, :associations, :events, :pictures, :main_picture, :news]
  before_action :set_current_volunteer, only: [:index, :show, :update, :search]

  def_param_group :volunteers_creation do
    param :mail, String, "Your mail address", :required => true
    param :password, String, "Chosen password, must contain letters and numbers", :required => true
    param :firstname, String, "Your firstname", :required => true
    param :lastname, String, "Your lastname", :required => true
    param :birthday, Date, "Your birthday"
    param :gender, String, "Must be 'm' or 'f'"
    param :city, String, "Your current city"
    param :latitude, Float, "Latitude position"
    param :longitude, Float, "Longitude position"
    param :allowgps, String, "Must be 'true' or 'false' for allowing geolocalisation"
    param :allow_notifications, String, "Must be 'true' or 'false' for allowing notifications"
  end

  def_param_group :volunteers_update do
    param :token, String, "Your token", :required => true
    param :mail, String, "Your mail address"
    param :password, String, "Chosen password, must contain letters and numbers"
    param :firstname, String, "Your firstname"
    param :lastname, String, "Your lastname"
    param :birthday, Date, "Your birthday"
    param :gender, String, "Must be 'm' or 'f'"
    param :city, String, "Your current city"
    param :latitude, Float, "Latitude position"
    param :longitude, Float, "Longitude position"
    param :allowgps, String, "Must be 'true' or 'false' for allowing geolocalisation"
    param :allow_notifications, String, "Must be 'true' or 'false' for allowing notifications"
  end
  
  api :GET, '/volunteers', "Get a list of all volunteers"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('index')
  def index
    query = "SELECT volunteers.id, mail, firstname, lastname, birthday, gender, " +
      "city, latitude, longitude, allowgps, allow_notifications, thumb_path, " +
      "(SELECT COUNT(*) FROM v_friends AS link INNER JOIN v_friends " +
      "ON link.friend_volunteer_id=v_friends.friend_volunteer_id WHERE " +
      "link.volunteer_id=#{@current_volunteer.id} AND " +
      "v_friends.volunteer_id=volunteers.id AND " +
      "v_friends.volunteer_id<>#{@current_volunteer.id}) AS nb_common_friends FROM volunteers"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  api :POST, '/volunteers', "Allow volunteer to create an account"
  param_group :volunteers_creation
  example SampleJson.volunteers('create')
  def create
    begin
      if Volunteer.exist? volunteer_params[:mail]
        render :json => create_error(400, t("volunteers.failure.mail.unavailable"))
        return
      end
      new_volunteer = Volunteer.create!(volunteer_params)
      render :json => create_response(new_volunteer.as_json(:except => [:password]))
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  api :GET, '/volunteers/:id', "Get volunteer informations by its id"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('show')
  def show
    begin

      if @current_volunteer.id == @volunteer.id
        render :json => create_response(@volunteer.as_json(:except => [:password, :token])
                                          .merge('friendship' => 'yourself')) and return
      end
      link = VFriend
        .where(:volunteer_id => @volunteer.id)
        .where(:friend_volunteer_id => @current_volunteer.id).first
      if link.eql?(nil)
        render :json => create_response(@volunteer.as_json(:except => [:password, :token])
                                          .merge('friendship' => 'false')) and return
      else
        render :json => create_response(@volunteer.as_json(:except => [:password, :token])
                                          .merge('friendship' => 'true')) and return
      end
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  api :GET, '/volunteers/search', "Search for volunteer by its firstname and/or lastname, return a list of matching volunteers"
  param :token, String, "Your token", :required => true
  param :research, String, "Volunteer firtname and/or lastname", :required => true
  example SampleJson.volunteers('search')
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
                  "(SELECT rights FROM av_links WHERE av_links.assoc_id=assocs.id AND av_links.volunteer_id=#{@current_volunteer.id}) AS rights", "'Assoc' AS result_type")
          .where(condition)
        
        condition = condition.gsub "name", "title"
        events = Event
          .select(:id, 'title AS name', :thumb_path,
                  "(SELECT rights FROM event_volunteers WHERE event_volunteers.event_id=events.id AND event_volunteers.volunteer_id=#{@current_volunteer.id}) AS rights", "'Event' AS result_type")
          .where(condition)
        

        condition = condition.gsub "title", "fullname"
        volunteers = Volunteer
          .select(:id, 'fullname AS name', :thumb_path,
                  "(SELECT COUNT(*) FROM v_friends WHERE v_friends.volunteer_id=volunteers.id AND v_friends.friend_volunteer_id=#{@current_volunteer.id}) AS rights", "'Volunteer' AS result_type")
          .where(condition)

        result = (assocs + events + volunteers).sort {|a,b| a['name']<=>b['name']}
        
        render :json => create_response(result) and return
      end

      render :json => create_error(400, t("volunteers.failure.research"))
    rescue => e
      render :json => create_error(400, t("volunteers.failure.research"))
    end
  end
  
  api :PUT, '/volunteers/:id', "Update volunteer"
  param_group :volunteers_update
  example SampleJson.volunteers('update')
  def update
    begin
      if @current_volunteer.id != @volunteer.id
        render :json => create_error(400, t("volunteers.failure.rights")) and return        
      end
      if !Volunteer.is_new_mail_available?(volunteer_params[:mail], @volunteer.mail)
        render :json => create_error(400, t("volunteers.failure.mail.unavailable"))
      elsif @volunteer.update!(volunteer_params)
        render :json => create_response(@volunteer.as_json(:except => [:password, :token])
                                          .merge('friendship' => 'yourself')) and return
      else
        render :json => create_error(400, t("volunteers.failure.update"))
      end
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  api :GET, '/volunteers/:id/notifications', "Get notifications of volunteer"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('notifications')
  def notifications  
    fields = "notifications.id, notifications.sender_id, notifications.sender_name, " +
      "notifications.receiver_id, notifications.receiver_name, " +
      "notifications.assoc_id, notifications.assoc_name, " +
      "notifications.event_id, notifications.event_name, " +
      "notifications.notif_type, notifications.created_at"

    query = "SELECT #{fields} FROM notifications WHERE " +
      "notifications.receiver_id=#{@volunteer.id} UNION " +
      "SELECT #{fields} FROM notifications INNER JOIN notification_volunteers ON " +
      "notification_volunteers.notification_id=notifications.id " +
      "WHERE notification_volunteers.volunteer_id=#{@volunteer.id} " +
      "ORDER BY created_at DESC"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  api :GET, '/volunteers/:id/friends', 'Return a list of the friends of the volunteer referred by id'
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('friends')
  def friends
    query = "SELECT volunteers.id, mail, firstname, lastname, birthday, gender, " +
      "city, latitude, longitude, allowgps, allow_notifications, thumb_path, " +
      "(SELECT COUNT(*) FROM v_friends AS link INNER JOIN v_friends " +
      "ON link.friend_volunteer_id=v_friends.friend_volunteer_id WHERE " +
      "link.volunteer_id=#{@volunteer.id} AND " +
      "v_friends.volunteer_id=volunteers.id AND " +
      "v_friends.volunteer_id<>#{@volunteer.id}) AS nb_common_friends FROM volunteers " +
      "INNER JOIN v_friends ON volunteers.id=v_friends.friend_volunteer_id WHERE v_friends.volunteer_id=#{@volunteer.id}"
    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  api :GET, '/volunteers/:id/associations', "Return a list of the volunteer's associations"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('associations')
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

  api :GET, '/volunteers/:id/events', "Return a list of the volunteer's events"
  param :token, String, "Your token", :required => true
  param :range, String, "can be 'past', 'current' or 'futur'", :required => true
  example SampleJson.volunteers('events')
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

  api :GET, '/volunteers/:id/pictures', "Return a list of all volunteer's pictures path"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('pictures')
  def pictures
    query = "id, file_size, picture_path, is_main"
    pictures = Picture.where(:volunteer_id => @volunteer.id)
      .where(:event_id => nil).where(:assoc_id => nil).select(query).limit(100)
    render :json => create_response(pictures)
  end

  api :GET, '/volunteers/:id/main_picture', "Return path of main picture"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('main_picture')
  def main_picture
    query = "id, file_size, picture_path"
    pictures = Picture.where(:volunteer_id => @volunteer.id)
      .where(:event_id => nil).where(:assoc_id => nil).where(:is_main => true)
      .select(query).first
    render :json => create_response(pictures)
  end

  api :GET, '/volunteers/:id/news', "Get volunteer's news"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('news')
  def news
    news = New::New
      .where(volunteer_id: @volunteer.id)
      .select(:id, :type, :volunteer_id, :title, :content)
      .joins("INNER JOIN volunteers ON volunteers.id=new_news.volunteer_id")
      .select("volunteers.firstname, volunteers.lastname, volunteers.thumb_path")
    render :json => create_response(news)
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

  def set_current_volunteer
    @current_volunteer = Volunteer.find_by(token: params[:token])
  end
  
  def volunteer_params
    params.permit(:mail, :password, :firstname, :lastname,
                  :birthday, :gender, :city, :latitude, :longitude,
                  :allowgps)
  end
  
  def generate_token
    SecureRandom.uuid.gsub(/\-/, '')
  end
end
