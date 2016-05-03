class EventsController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_event, only: [:show, :edit, :update, :notifications, :guests, :delete]
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
  example SampleJson.events('index')
  def index
    query = "SELECT events.id, events.title, events.place, events.begin, events.assoc_id, " +
      "(SELECT event_volunteers.rights FROM event_volunteers WHERE event_volunteers.event_id=" + 
      "events.id AND event_volunteers.volunteer_id=#{@volunteer.id}) AS rights, " + 
      "(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON " +
      "event_volunteers.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members" +
      " FROM events"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
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

      render :json => create_response(new_event.complete_description(event_link.rights))
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
      render :json => create_response(@event.complete_description(link.rights)) and return
    end
    rights = 'none'

    notif = Notification::InviteGuest.where(event_id: @event.id)
      .where(volunteer_id: @volunteer.id).first
    
    if notif != nil
      rights = 'invited'
    end

    notif = Notification::JoinEvent.where(event_id: @event.id)
      .where(volunteer_id: @volunteer.id).first

    if notif != nil
      rights = 'waiting'
    end

    render :json => create_response(@event.complete_description(rights))
  end

  api :GET, '/events/search', "Search for event by its name, return a list of matching events"
  param :token, String, "Your token", :required => true
  param :research, String, "Event's name", :required => true
  param :assoc_id, String, "Assoc's id to get only its events"
  example SampleJson.events('search')
  def search
    begin
      name = params[:research].downcase
      assoc_id = params[:assoc_id]
      if name.length.eql?(0)
        render :json => create_error(400, t("events.failure.research")) and return
      end
      
      if assoc_id.eql?(nil)
        query = "lower(title) LIKE ?"
        render :json => create_response(Event.select('id, title, description, place, begin')
                                          .where(query, "#{name}%"))
      else
        query = "lower(title) LIKE ?"
        render :json => create_response(Event.select('id, title, description, place, begin')
                                          .where(:assoc_id => assoc_id)
                                          .where(query, "#{name}%"))
      end
    rescue => e
      render :json => create_error(400, t("events.failure.research")) and return
    end
  end

  api :GET, '/events/:id/notifications', 'Get event notifications'
  param :token, String, "Your token", :required => true
  example SampleJson.events('notifications')
  def notifications
    render :json => create_response(@event.notifications)
  end

  api :GET, '/events/:id/guests', 'Get a list of all guests'
  param :token, String, "Your token", :required => true
  example SampleJson.events('guests')
  def guests
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.mail, event_volunteers.rights"
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
      render :json => create_response(@event.complete_description(@link.rights))
    rescue Exception => e
      render :json => create_error(400, e.to_s) and return
    end
  end
  

  api :DELETE, '/events/:id', "Delete event (need to be host)"
  param :token, String, "Your token", :required => true
  example SampleJson.events('delete')
  def delete
    if @link.rights.eql?('host')
      Notification::JoinEvent.where(event_id: @event.id).destroy_all
      Notification::InviteGuest.where(event_id: @event.id).destroy_all
      EventVolunteer.where(event_id: @event.id).destroy_all
      @event.destroy
      render :json => create_response(t("events.success.deleted")) and return
    end
    render :json => create_error(400, t("events.failure.rights"))    
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

  def event_params_creation
    params.permit(:title, :description, :place, :begin, :end, :assoc_id)
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
