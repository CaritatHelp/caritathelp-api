class EventsController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_assoc, only: [:create]
  before_action :set_event, only: [:show, :edit, :update, :notifications, :guests, :delete, :pictures, :main_picture, :news]
  before_action :check_rights, only: [:update, :delete]

  def_param_group :create_event do
    param :token, String, "Creator's token", :required => true
    param :assoc_id, String, "Association's id", :required => true
    param :title, String, "Title of the event", :required => true
    param :description, String, "Association's description", :required => true
    param :place, String, "Place where the event will take place"
    param :begin, Date, "Beginning of the event"
    param :end, Date, "End of the event"
  end

  def_param_group :update_event do
    param :token, String, "Creator's token", :required => true
    param :title, String, "Title of the event"
    param :description, String, "Association's description"
    param :place, String, "Place where the event will take place"
    param :begin, Date, "Beginning of the event"
    param :end, Date, "End of the event"
  end

  api :GET, '/events', "Get a list of all events"
  param :token, String, "Your token", :required => true
  param :range, String, "can be 'past', 'current' or 'futur'", :required => true
  example SampleJson.events('index')
  def index
    events = Event.select("events.*")
      .select("(SELECT event_volunteers.rights FROM event_volunteers WHERE event_volunteers.event_id=events.id AND event_volunteers.volunteer_id=#{@volunteer.id}) AS rights")
      .select("(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest")
      .select("(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON event_volunteers.volunteer_id=v_friends.friend_volunteer_id WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members")
    render :json => create_response(events)
  end

  api :POST, '/events', "Allow an association to create an event"
  param_group :create_event
  example SampleJson.events('create')
  def create
    begin
      @assoc = Assoc.find_by!(id: params[:assoc_id])

      if @assoc == nil
        render :json => create_error(400, t("events.failure.wrong_assoc")) and return
      end

      assoc_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @volunteer.id).first

      if assoc_link == nil || assoc_link.rights.eql?('member')
        render :json => create_error(400, t("events.failure.rights")) and return        
      end
      
      new_event = Event.create!(event_params_creation)

      event_link = EventVolunteer.create!(event_id: new_event.id,
                                          volunteer_id: @volunteer.id,
                                          rights: 'host')

      render :json => create_response(new_event.as_json.merge("rights" => "host"))
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      begin
        new_event.destroy
      rescue
      end
      render :json => create_error(400, e.to_s) and return
    end
  end
  
  api :GET, '/events/:id', "Get events information by its id"
  param :token, String, "Your token", :required => true
  example SampleJson.events('show')
  def show
    link = EventVolunteer.where(event_id: @event.id).where(volunteer_id: @volunteer.id).first
    if link != nil
      render :json => create_response(@event.as_json.merge('rights' => link.rights)) and return
    end
    rights = 'none'

    notif = Notification.where(notif_type: 'InviteGuest')
      .where(event_id: @event.id)
      .where(receiver_id: @volunteer.id).first
    
    if notif != nil
      rights = 'invited'
    end

    notif = Notification.where(notif_type: 'JoinEvent')
      .where(event_id: @event.id)
      .where(sender_id: @volunteer.id).first

    if notif != nil
      rights = 'waiting'
    end

    render :json => create_response(@event.as_json.merge('rights' => rights))
  end

  api :GET, '/events/:id/guests', 'Get a list of all guests'
  param :token, String, "Your token", :required => true
  example SampleJson.events('guests')
  def guests
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.mail, volunteers.thumb_path, event_volunteers.rights"
    render :json => create_response(Volunteer.joins(:event_volunteers)
                                      .where(event_volunteers: { event_id: @event.id })
                                      .select(query).limit(100))
  end

  api :PUT, '/events/:id', "Update event"
  param_group :update_event
  example SampleJson.events('update')
  def update
    begin
      @event.update!(event_params_update)
      render :json => create_response(@event.as_json.merge('rights' => @link.rights))
    rescue Exception => e
      render :json => create_error(400, e.to_s) and return
    end
  end
  

  api :DELETE, '/events/:id', "Delete event (need to be host)"
  param :token, String, "Your token", :required => true
  example SampleJson.events('delete')
  def delete
    if @link.rights.eql?('host')
      Notification.where(event_id: @event.id).destroy_all
      EventVolunteer.where(event_id: @event.id).destroy_all
      @event.destroy
      render :json => create_response(t("events.success.deleted")) and return
    end
    render :json => create_error(400, t("events.failure.rights"))    
  end

  api :GET, '/events/owned', "Get all event where you're owner"
  param :token, String, "Your token", :required => true
  example SampleJson.events('owned')
  def owned
    events = Event.select(:id, :title, :place, :begin, :end, :assoc_id, :thumb_path)
      .select("(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest")
      .select("(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON event_volunteers.volunteer_id=v_friends.friend_volunteer_id WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members")
      .joins("INNER JOIN event_volunteers ON event_volunteers.event_id=events.id")
      .select("event_volunteers.rights AS rights")
      .where("event_volunteers.volunteer_id=#{@volunteer.id} AND event_volunteers.rights='host'")
    render :json => create_response(events)
  end

  api :GET, '/events/invited', "Get all event where you're invited"
  param :token, String, "Your token", :required => true
  example SampleJson.events('invited')
  def invited
    events = Event.select(:id, :title, :place, :begin, :end, :assoc_id, :thumb_path)
      .select("(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest")
      .select("(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON event_volunteers.volunteer_id=v_friends.friend_volunteer_id WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members")
      .joins("INNER JOIN notifications ON notifications.event_id=events.id")
      .select("notifications.id AS notif_id")
      .where("notifications.receiver_id=#{@volunteer.id} AND notifications.notif_type='InviteGuest'")
    render :json => create_response(events)
  end

  api :GET, '/events/:id/pictures', "Return a list of all event's pictures path"
  param :token, String, "Your token", :required => true
  example SampleJson.events('pictures')
  def pictures
    query = "id, file_size, picture_path, is_main"
    pictures = Picture.where(:event_id => @event.id).select(query).limit(100)
    render :json => create_response(pictures)
  end

  api :GET, '/events/:id/main_picture', "Return path of main picture"
  param :token, String, "Your token", :required => true
  example SampleJson.events('main_picture')
  def main_picture
    query = "id, file_size, picture_path"
    pictures = Picture.where(:event_id => @event.id).where(:is_main => true).select(query).first
    render :json => create_response(pictures)
  end
  
  api :GET, '/events/:id/news', "Get event's news"
  param :token, String, "Your token", :required => true
  example SampleJson.events('news')
  def news
    news = New::New
      .where(event_id: @event.id)
      .select("new_news.*, new_news.type AS news_type")
      .joins("INNER JOIN events ON events.id=new_news.event_id")
      .select("events.title AS name, events.thumb_path")
      .select("(SELECT fullname FROM volunteers WHERE volunteers.id=new_news.volunteer_id) AS volunteer_fullname")
      .select("(SELECT thumb_path FROM volunteers WHERE volunteers.id=new_news.volunteer_id) AS volunteer_thumb_path")
    render :json => create_response(news)
  end

  private
  def set_volunteer
    @volunteer = Volunteer.find_by(token: params[:token])
  end

  def set_event
    begin
      @event = Event.find(params[:id])
    rescue
      render :json => create_error(400, t("events.failure.id"))
    end
  end

  def set_assoc
    begin
      @assoc = Assoc.find(params[:assoc_id])
    rescue
      render :json => create_error(400, t("assocs.failure.id"))
    end
  end

  def event_params_creation
    params_event = params.permit(:title, :description, :place, :begin, :end, :assoc_id)
    params_event[:assoc_name] = @assoc.name
    params_event
  end

  def event_params_update
    params.permit(:title, :description, :place, :begin, :end)
  end

  def check_rights
    @link = EventVolunteer.where(:volunteer_id => @volunteer.id)
      .where(:event_id => @event.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("events.failure.rights"))
      return false
    end
    return true
  end
end
