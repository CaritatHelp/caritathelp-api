class EventsController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_event, only: [:show, :edit, :update, :notifications, :guests]
  before_action :check_rights, only: [:update]

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
    render :json => create_response(Event.select('id, title, description, place, begin, assoc_id').limit(100))
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

      event_link = EventVolunteer.create!([event_id: new_event.id,
                                          volunteer_id: @volunteer.id,
                                          rights: 'host'])

      render :json => create_response(new_event)
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
    render :json => create_response(@event.complete_description)
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
    render :json => create_response(@event.volunteers)
  end

  api :PUT, '/events/:id', "Update event"
  param_group :update_event
  example SampleJson.events('update')
  def update
    begin
      @event.update!(event_params_update)
      render :json => create_response(@event.complete_description)
    rescue Exception => e
      render :json => create_error(400, e.to_s) and return
    end
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
