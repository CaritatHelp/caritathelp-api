class AssocsController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_assoc, only: [:show, :edit, :update, :notifications, :members, :events]
  before_action :check_rights, only: [:update]

  def_param_group :assocs_create do
    param :token, String, "Creator's token", :required => true
    param :name, String, "Association's name", :required => true
    param :description, String, "Association's description", :required => true
    param :birthday, Date, "Date of creation"
    param :city, String, "City where the association is located"
    param :latitude, Float, "Association latitude position"
    param :longitude, Float, "Association longitude position"
  end

  def_param_group :assocs_update do
    param :token, String, "Creator's token, must be owner or admin of the association",
    :required => true
    param :name, String, "Association's name"
    param :description, String, "Association's description"
    param :birthday, Date, "Date of creation"
    param :city, String, "City where the association is located"
    param :latitude, Float, "Association latitude position"
    param :longitude, Float, "Association longitude position"
  end

  api :GET, '/associations', "Get a list of all associations"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('index')
  def index
    render :json => create_response(Assoc.select('id, name, description, birthday, city, latitude, longitude').limit(100))
  end

  api :POST, '/associations', "Allow volunteer to create an association"
  param_group :assocs_create
  example SampleJson.assocs('create')
  def create
    begin
      if Assoc.exist? assoc_params[:name]
        render :json => create_error(400, t("assocs.failure.name.unavailable"))
        return
      end
      new_assoc = Assoc.create!(assoc_params)
      
      link = AvLink.create!(assoc_id: new_assoc.id,
                            volunteer_id: @volunteer.id, rights: 'owner')

      render :json => create_response(new_assoc.complete_description(link.rights))
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  api :GET, '/associations/:id', "Get associations information by its id"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('show')
  def show
    link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @volunteer.id).first
    if  link != nil
      render :json => create_response(@assoc.complete_description(link.rights)) and return
    end
    render :json => create_response(@assoc.complete_description)
  end

  api :GET, '/associations/search', "Search for association by its name, return a list of matching associations"
  param :token, String, "Your token", :required => true
  param :research, String, "Association's name", :required => true
  example SampleJson.assocs('search')
  def search
    begin
      name = params[:research].downcase

      if name.length.eql?(0)
        render :json => create_error(400, t("assocs.failure.research")) and return
      end
      query = "lower(name) LIKE ?"
      render :json => create_response(Assoc.select('id, name, description, city')
                                        .where(query, "#{name}%"))
    rescue => e
      render :json => create_error(400, t("assocs.failure.research")) and return
    end
  end

  api :GET, '/associations/:id/notifications', 'Get assoc notifications'
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('notifications')
  def notifications
    render :json => create_response(@assoc.notifications)
  end

  api :GET, '/associations/:id/members', 'Get a list of all members'
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('members')
  def members
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.mail, av_links.rights"
    render :json => create_response(Volunteer.joins(:av_links)
                                      .where(av_links: { assoc_id: @assoc.id })
                                      .select(query).limit(100))
  end

  api :GET, '/associations/:id/events', "Get a list of all association's events"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('events')
  def events
    render :json => create_response(@assoc.events)
  end

  api :PUT, '/associations/:id', "Update association"
  param_group :assocs_update
  example SampleJson.assocs('update')
  def update
    begin
      if !Assoc.is_new_name_available?(assoc_params[:name],
                                             @assoc.name)
        render :json => create_error(400, t("assocs.failure.name.unavailable"))
      elsif @assoc.update!(assoc_params)
        render :json => create_response(@assoc.complete_description(@link.rights))
      else
        render :json => create_error(400, t("assocs.failure.update"))
      end
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  private
  def set_assoc
    begin
      @assoc = Assoc.find(params[:id])
    rescue
      render :json => create_error(400, t("assocs.failure.id"))
    end
  end

  def set_volunteer
    @volunteer = Volunteer.find_by(token: params[:token])
  end

  def assoc_params
    params.permit(:name, :description, :birthday, :city, :latitude, :longitude)
  end

  def check_rights
    @link = AvLink.where(:volunteer_id => @volunteer.id)
      .where(:assoc_id => @assoc.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("assocs.failure.rights"))
      return false
    end
    return true
  end
end
