class NewsController < ApplicationController
  swagger_controller :news, "News manager"

  before_action :authenticate_volunteer!, unless: :is_swagger_request?

  before_action :set_new, only: [:show, :comments]
  before_action :check_news_rights, only: [:show, :comments]

  swagger_api :index do
    summary "Get all news concerning the volunteer refered by the token"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def index
    volunteer_news = current_volunteer.news.flatten
    friends_news = current_volunteer.v_friends.map { |link| link.volunteer.news }.flatten
    assocs_news = current_volunteer.assocs.map { |assoc| assoc.news.select{ |new| (new.private and current_volunteer.av_links.find_by(assoc_id: assoc.id).level >= AvLink.levels["member"]) or new.public } }.flatten
    events_news = current_volunteer.events.map { |event| event.news.select { |new| (new.private and current_volunteer.event_volunteers.find_by(event_id: event.id).level >= EventVolunteer.levels["member"]) or new.public} }.flatten

    render json: create_response((volunteer_news + friends_news + assocs_news + events_news).sort{ |a, b| b.updated_at <=> a.updated_at })
  end

  swagger_api :wall_message do
    summary "Creates a wall message for yourself, friend, assoc or event"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :content, :string, :required, "New's content"
    param :query, :group_id, :integer, :required, "Id of Event, Assoc or Volunteer"
    param :query, :group_type, :string, :required, "Id's type"
    param :query, :news_type, :string, :required, "'Status' is the only possibility for now"
    param :query, :title, :string, :optional, "New's title"
    param :query, :private, :boolean, :optional, "true to make it private"
    response :ok
  end
  def wall_message
    new = New.new(new_params)
    new.volunteer_id = current_volunteer.id
    
    if new.save
      render json: create_response(new), status: :ok
    else
      render json: create_error(400, new.errors), status: :bad_request
    end
  end
  
  swagger_api :show do
    summary "Get new's information"
    param :path, :id, :integer, :required, "New's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def show
    render json: create_response(@new)
  end

  swagger_api :comments do
    summary "Get new's comments"
    param :path, :id, :integer, :required, "New's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
  end
  def comments
    render json: create_response(@new.comments.order(created_at: :asc)
                                  .map { |com|
                                   com.attributes.merge(thumb_path: com.volunteer.thumb_path,
                                                        firstname: com.volunteer.firstname,
                                                        lastname: com.volunteer.lastname)})
  end

  private
  def set_new
    begin
      @new = New.find(params[:id])
    rescue
      render :json => create_error(400, t("news.failure.id"))
    end
  end

  def new_params
    params.permit(:news_type, :group_id, :group_type, :private, :content, :title)
  end  

  def check_news_rights
    if @new.private
      level = current_volunteer.av_links.find_by(assoc_id: @new.group_id).try(:level) if @new.group_type == "Assoc"
      level = current_volunteer.event_volunteers.find_by(event_id: @new.group_id).try(:level) if @new.group_type == "Event"
      if ((@new.group_type == "Assoc" and (level.blank? or level < AvLink.levels["member"])) || (@new.group_type == "Event" and (level.blank? or level < EventVolunteer.levels["member"])) || (@new.group_type == "Volunteer" and current_volunteer.v_friends.find_by(friend_volunteer_id: @new.group_id)))
        render json: create_error(400, t("volunteers.failure.rights"))
      end
    end
  end
  
  def check_assoc_rights
    @link = AvLink.where(:volunteer_id => current_volunteer.id)
      .where(:assoc_id => @assoc.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("assocs.failure.rights"))
      return false
    end
    return true
  end
end
