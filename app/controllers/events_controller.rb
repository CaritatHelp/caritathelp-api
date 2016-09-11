class EventsController < ApplicationController
  swagger_controller :events, "Events management"

  before_filter :check_token
  before_action :set_volunteer
  before_action :set_assoc, only: [:create]
  before_action :set_event, only: [:show, :edit, :update, :notifications, :guests, :delete, :pictures, :main_picture, :news, :raise_emergency]
  before_action :set_link, only: [:update, :delete, :show, :raise_emergency]
  before_action :check_privacy, only: [:show, :guests, :pictures, :main_picture, :news]
  before_action :check_rights, only: [:update, :delete, :raise_emergency]

  swagger_api :index do
    summary "Get a list of all events"
    param :query, :token, :string, :required, "Your token"
    param :query, :range, :string, :optional, "Can be 'past', 'current' or 'futur'"
    response :ok
  end
  def index
    events = Event.select("events.*")
      .select("(SELECT event_volunteers.rights FROM event_volunteers WHERE event_volunteers.event_id=events.id AND event_volunteers.volunteer_id=#{@volunteer.id}) AS rights")
      .select("(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest")
      .select("(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON event_volunteers.volunteer_id=v_friends.friend_volunteer_id WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members")
      .where(private: false)
    render :json => create_response(events)
  end

  swagger_api :create do
    summary "Allow an association to create an event"
    param :query, :token, :string, :required, "Your token"
    param :form, :assoc_id, :integer, :required, "Association's id"
    param :form, :title, :string, :required, "Event's title"
    param :form, :description, :string, :required, "Event's description"
    param :form, :begin, :date, :required, "Beginning of the event"
    param :form, :end, :date, :required, "End of the event"
    param :form, :place, :string, :optional, "Where the event takes place"
    response :ok
  end
  def create
    begin
      @assoc = Assoc.find_by!(id: params[:assoc_id])

      if @assoc == nil
        render :json => create_error(400, t("events.failure.wrong_assoc")) and return
      end

      assoc_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @volunteer.id).first

      if assoc_link == nil or assoc_link.level < AvLink.levels["admin"]
        render :json => create_error(400, t("events.failure.rights")) and return        
      end
      
      new_event = Event.new(event_params_creation)
      if !new_event.save
        render :json => create_error(400, new_event.errors) and return
      end

      event_link = EventVolunteer.create!(event_id: new_event.id,
                                          volunteer_id: @volunteer.id,
                                          rights: 'host')

      render :json => create_response(new_event.as_json.merge("rights" => "host"))
    rescue => e
      begin
        new_event.destroy
      rescue
      end
      render :json => create_error(400, e.to_s) and return
    end
  end
  
  swagger_api :show do
    summary "Returns event's information"
    param :path, :id, :integer, :required, "Event's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def show
    if @link != nil
      render :json => create_response(@event.as_json.merge('rights' => @link.rights)) and return
    end
    rights = nil

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

  swagger_api :guests do
    summary "Returns a list of all guests"
    param :path, :id, :integer, :required, "Event's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def guests
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.mail, volunteers.thumb_path, event_volunteers.rights"
    render :json => create_response(Volunteer.joins(:event_volunteers)
                                      .where(event_volunteers: { event_id: @event.id })
                                      .select(query).limit(100))
  end

  swagger_api :update do
    summary "Updates event"
    param :path, :id, :integer, :required, "Event's id"
    param :query, :token, :string, :required, "Your token"
    param :form, :title, :string, :optional, "Event's title"
    param :form, :description, :string, :optional, "Event's description"
    param :form, :begin, :date, :optional, "Beginning of the event"
    param :form, :end, :date, :optional, "End of the event"
    param :form, :place, :string, :optional, "Where the event takes place"
    response :ok
  end
  def update
    begin
      @event.update!(event_params_update)
      render :json => create_response(@event.as_json.merge('rights' => @link.rights))
    rescue Exception => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :delete do
    summary "Deletes event (needs to be host)"
    param :path, :id, :integer, :required, "Event's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def delete
    if @link.rights.eql?('host')
      Notification.where(event_id: @event.id).destroy_all
      EventVolunteer.where(event_id: @event.id).destroy_all
      @event.destroy
      render :json => create_response(t("events.success.deleted")) and return
    end
    render :json => create_error(400, t("events.failure.rights"))    
  end

  swagger_api :owned do
    summary "Get all event where you're the owner"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def owned
    events = Event.select(:id, :title, :place, :begin, :end, :assoc_id, :thumb_path)
      .select("(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest")
      .select("(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON event_volunteers.volunteer_id=v_friends.friend_volunteer_id WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members")
      .joins("INNER JOIN event_volunteers ON event_volunteers.event_id=events.id")
      .select("event_volunteers.rights AS rights")
      .where("event_volunteers.volunteer_id=#{@volunteer.id} AND event_volunteers.rights='host'")
    render :json => create_response(events)
  end

  swagger_api :invited do
    summary "Get all event where you're invited"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def invited
    events = Event.select(:id, :title, :place, :begin, :end, :assoc_id, :thumb_path)
      .select("(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest")
      .select("(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON event_volunteers.volunteer_id=v_friends.friend_volunteer_id WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members")
      .joins("INNER JOIN notifications ON notifications.event_id=events.id")
      .select("notifications.id AS notif_id")
      .where("notifications.receiver_id=#{@volunteer.id} AND notifications.notif_type='InviteGuest'")
    render :json => create_response(events)
  end

  swagger_api :pictures do
    summary "Returns a list of all event's pictures paths"
    param :path, :id, :integer, :required, "Event's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def pictures
    query = "id, file_size, picture_path, is_main"
    pictures = Picture.where(:event_id => @event.id).select(query).limit(100)
    render :json => create_response(pictures)
  end

  swagger_api :main_picture do
    summary "Returns path of main picture"
    param :path, :id, :integer, :required, "Event's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def main_picture
    query = "id, file_size, picture_path"
    pictures = Picture.where(:event_id => @event.id).where(:is_main => true).select(query).first
    render :json => create_response(pictures)
  end
  
  swagger_api :news do
    summary "Returns event's news"
    param :path, :id, :integer, :required, "Event's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def news
    rights = @volunteer.event_volunteers.find_by(event_id: @event.id).try(:level)
    render json: create_response(@event.news.select { |new| (new.private and rights.present? and rights >= EventVolunteer.levels["member"]) or new.public })
  end

  # TO TEST
  swagger_api :raise_emergency do
    summary "Raise an emergency to call for volunteers"
    param :path, :id, :integer, :required, "Event's id"
    param :query, :token, :string, :required, "Your token"
    param :query, :number_volunteers, :integer, :required, "Number of volunteers you need"
    param :query, :zone, :integer, :optional, "Size (in km) of the zone, default: 50km"
    response :ok
  end
  def raise_emergency
    zone = 50.to_f
    zone = params[:zone].to_f if params[:zone].present?

    volunteers = @event.assoc.volunteers.select { |volunteer|
      volunteer.allowgps and volunteer.distance_from_event_in_km(@event) < zone
    }

    volunteers.each do |volunteer|
      notification = Notification.create(create_emergency_notification(volunteer))
      send_notif_to_socket(notification)
    end
    
    render json: volunteers
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
    params_event = params.permit(:title, :description, :place, :begin, :end, :assoc_id, :private)
    params_event[:assoc_name] = @assoc.name
    params_event
  end

  def event_params_update
    params.permit(:title, :description, :place, :begin, :end, :private)
  end

  def set_link
    @link = EventVolunteer.where(:volunteer_id => @volunteer.id).where(:event_id => @event.id).first
  end

  def check_privacy
    assoc_link = AvLink.where(volunteer_id: @volunteer.id).where(assoc_id: @event.assoc_id).first
    if @event.private.eql?(true) and (assoc_link.eql?(nil) or assoc_link.level < AvLink.levels["member"])
      render :json => create_error(400, t("events.failure.rights")) and return      
    end
  end

  def create_emergency_notification(volunteer)
    {event_id: @event.id,
     event_name: @event.title,
     thumb_path: @event.thumb_path,
     sender_id: @volunteer.id,
     sender_name: @volunteer.fullname,
     receiver_id: volunteer.id,
     receiver_name: volunteer.fullname,
     notif_type: 'Emergency'}
  end
  
  def check_rights
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("events.failure.rights"))
      return false
    end
    return true
  end
end
