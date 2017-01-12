class EventsController < ApplicationController
  swagger_controller :events, "Events management"

  before_action :authenticate_volunteer!, except: [:index, :show, :pictures, :main_picture],
                unless: :is_swagger_request?
  before_action :authenticate_volunteer_if_needed,
                only: [:index, :show, :pictures, :main_picture], unless: :is_swagger_request?

  before_action :set_assoc, only: [:create]
  before_action :set_event, only: [:show, :edit, :update, :notifications, :guests, :delete, :pictures, :main_picture, :news, :raise_emergency, :volunteers_from_emergency, :invitable_volunteers]
  before_action :set_link, only: [:update, :delete, :show, :raise_emergency]
  before_action :check_privacy, only: [:show, :guests, :pictures, :main_picture, :news]
  before_action :check_rights, only: [:update, :delete, :raise_emergency]

  swagger_api :index do
    summary "Get a list of all events"
    param :header, 'access-token', :string, :optional, "Access token"
    param :header, :client, :string, :optional, "Client token"
    param :header, :uid, :string, :optional, "Volunteer's uid (email address)"
    param :query, :range, :string, :optional, "Can be 'past', 'current' or 'futur'"
    response :ok
  end
  def index
    events = Event.all.select { |event|
      if current_volunteer.blank?
        event.public
      else
        event.public or event.volunteers.include?(current_volunteer)
      end
    }.map { |event|
      if current_volunteer.present?
        link = event.event_volunteers.find_by(volunteer_id: current_volunteer.id)
        friends_number = event.volunteers.select { |volunteer|
          volunteer.volunteers.include?(current_volunteer)
        }.count
      end
      friends_number = 0 if friends_number.blank?
      event.attributes.merge(rights: link.try(:rights),
                             nb_guest: event.volunteers.count,
                             nb_friends_members: friends_number)
    }
    render json: create_response(events)
  end

  swagger_api :create do
    summary "Allow an association to create an event"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :form, :assoc_id, :integer, :required, "Association's id"
    param :form, :title, :string, :required, "Event's title"
    param :form, :description, :string, :required, "Event's description"
    param :form, :begin, :date, :required, "Beginning of the event"
    param :form, :end, :date, :required, "End of the event"
    param :form, :place, :string, :optional, "Where the event takes place"
    param :form, :private, :boolean, :optional, "true to make the event private, false otherwise"
    response :ok
  end
  def create
    begin
      @assoc = Assoc.find_by!(id: params[:assoc_id])

      if @assoc == nil
        render :json => create_error(400, t("events.failure.wrong_assoc")) and return
      end

      assoc_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: current_volunteer.id).first

      if assoc_link == nil or assoc_link.level < AvLink.levels["admin"]
        render :json => create_error(400, t("events.failure.rights")) and return
      end

      new_event = Event.new(event_params_creation)
      if !new_event.save
        render :json => create_error(400, new_event.errors) and return
      end

      event_link = EventVolunteer.create!(event_id: new_event.id,
                                          volunteer_id: current_volunteer.id,
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
    param :header, 'access-token', :string, :optional, "Access token"
    param :header, :client, :string, :optional, "Client token"
    param :header, :uid, :string, :optional, "Volunteer's uid (email address)"
    response :ok
  end
  def show
    if current_volunteer.blank?
      render json: create_response(@event) and return
    end

    if @link != nil
      render :json => create_response(@event.as_json.merge('rights' => @link.rights)) and return
    end
    rights = nil

    notif = Notification.where(notif_type: 'InviteGuest')
      .where(event_id: @event.id)
      .where(receiver_id: current_volunteer.id).first

    if notif != nil
      rights = 'invited'
    end

    notif = Notification.where(notif_type: 'JoinEvent')
      .where(event_id: @event.id)
      .where(sender_id: current_volunteer.id).first

    if notif != nil
      rights = 'waiting'
    end

    render :json => create_response(@event.as_json.merge('rights' => rights))
  end

  swagger_api :guests do
    summary "Returns a list of all guests"
    param :path, :id, :integer, :required, "Event's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def guests
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.fullname, volunteers.email, volunteers.thumb_path, event_volunteers.rights"
    render :json => create_response(Volunteer.joins(:event_volunteers)
                                      .where(event_volunteers: { event_id: @event.id })
                                      .select(query).limit(100))
  end

  swagger_api :update do
    summary "Updates event"
    param :path, :id, :integer, :required, "Event's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
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
      @event.update_all
      render :json => create_response(@event.as_json.merge('rights' => @link.rights))
    rescue Exception => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :delete do
    summary "Deletes event (needs to be host)"
    param :path, :id, :integer, :required, "Event's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
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

  swagger_api :invitable_volunteers do
    summary "Get a list of all invitable volunteers"
    param :path, :id, :integer, :required, "Event's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def invitable_volunteers
    volunteers = @event.assoc.volunteers.select { |volunteer| volunteer.events.exclude?(@event) }
    volunteers = volunteers.select { |volunteer|
    	Notification.find_by(receiver_id: volunteer.id, event_id: @event.id, notif_type: "InviteGuest").blank? and Notification.find_by(sender_id: volunteer.id, event_id: @event.id, notif_type: "JoinEvent").blank?
    }
    render json: create_response(volunteers)
  end

  swagger_api :owned do
    summary "Get all event where you're the owner"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def owned
    events = Event.select(:id, :title, :place, :begin, :end, :assoc_id, :thumb_path)
      .select("(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest")
      .select("(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON event_volunteers.volunteer_id=v_friends.friend_volunteer_id WHERE event_id=events.id AND v_friends.volunteer_id=#{current_volunteer.id}) AS nb_friends_members")
      .joins("INNER JOIN event_volunteers ON event_volunteers.event_id=events.id")
      .select("event_volunteers.rights AS rights")
      .where("event_volunteers.volunteer_id=#{current_volunteer.id} AND event_volunteers.rights='host'")
    render :json => create_response(events)
  end

  swagger_api :invited do
    summary "Get all event where you're invited"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def invited
    events = Event.select(:id, :title, :place, :begin, :end, :assoc_id, :thumb_path)
      .select("(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest")
      .select("(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON event_volunteers.volunteer_id=v_friends.friend_volunteer_id WHERE event_id=events.id AND v_friends.volunteer_id=#{current_volunteer.id}) AS nb_friends_members")
      .joins("INNER JOIN notifications ON notifications.event_id=events.id")
      .select("notifications.id AS notif_id")
      .where("notifications.receiver_id=#{current_volunteer.id} AND notifications.notif_type='InviteGuest'")
    render :json => create_response(events)
  end

  swagger_api :joining do
    summary "Get all event where you're joining"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def joining
    events = current_volunteer.notifications.select(&:is_join_event?).select { |notification|
      notification.sender_id == current_volunteer.id
    }.map { |notification| Event.find(notification.event_id) }
    render json: create_response(events)
  end

  swagger_api :pictures do
    summary "Returns a list of all event's pictures paths"
    param :path, :id, :integer, :required, "Event's id"
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
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def news
    rights = current_volunteer.event_volunteers.find_by(event_id: @event.id).try(:level)
    render json: create_response(@event.news.select { |new| (new.private and rights.present? and rights >= EventVolunteer.levels["member"]) or new.public })
  end

  swagger_api :raise_emergency do
    summary "Raise an emergency to call for volunteers"
    param :path, :id, :integer, :required, "Event's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :number_volunteers, :integer, :optional, "Number of volunteers you need"
    param :query, :zone, :integer, :optional, "Size (in km) of the zone, default: 50km"
    response :ok
    response 400, "Event must be located (latitude/longitude) to raise an emergency"
  end
  def raise_emergency
    zone = 50.to_f
    zone = params[:zone].to_f if params[:zone].present?

    if @event.latitude.blank? or @event.longitude.blank?
      render json: create_error(400, t("events.failure.no_position")) and return
    end
    volunteers = @event.assoc.volunteers.select { |volunteer|
      volunteer.allowgps and volunteer.distance_from_event_in_km(@event) < zone and @event.volunteers.exclude? volunteer
    }

    volunteers.each do |volunteer|
      notification = Notification.create(create_emergency_notification(volunteer))
      send_notif_to_socket(notification) unless Rails.env.test?
    end

    render json: create_response(volunteers)
  end

  swagger_api :volunteers_from_emergency do
    summary "Returns a list of volunteers who accepted to join the event from emergency"
    param :path, :id, :integer, :required, "Event's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def volunteers_from_emergency
    render json: create_response(Notification.select(&:accepted_emergency?).select { |notif|
                                  notif.accepted_emergency? and notif.sender_id == @event.id
                                }.map { |notif| Volunteer.find(notif.receiver_id) })
  end

  private
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
    return nil if current_volunteer.blank?
    @link = EventVolunteer.where(:volunteer_id => current_volunteer.id).where(:event_id => @event.id).first
  end

  def check_privacy
    render :json => create_error(400, t("events.failure.rights")) and return if current_volunteer.blank? and @event.private
    return true if current_volunteer.blank? and @event.public
    assoc_link = AvLink.where(volunteer_id: current_volunteer.id).where(assoc_id: @event.assoc_id).first
    if @event.private and (assoc_link.eql?(nil) or assoc_link.level < AvLink.levels["member"])
      render :json => create_error(400, t("events.failure.rights")) and return
    end
  end

  def create_emergency_notification(volunteer)
    {event_id: @event.id,
     event_name: @event.title,
     sender_thumb_path: @event.thumb_path,
     sender_id: current_volunteer.id,
     sender_name: current_volunteer.fullname,
     receiver_id: volunteer.id,
     receiver_name: volunteer.fullname,
     receiver_thumb_path: volunteer.thumb_path,
     notif_type: 'Emergency'}
  end

  def check_rights
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("events.failure.rights"))
      return false
    end
    return true
  end

  def authenticate_volunteer_if_needed
    if request.headers["access-token"].present? and request.headers["client"].present? and request.headers["uid"].present?
      authenticate_volunteer!
    end
  end
end
