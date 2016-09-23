class AssocsController < ApplicationController
  swagger_controller :assocs, "Associations management"
  
  before_action :authenticate_volunteer!, unless: :is_swagger_request?
  
  before_action :set_link, only: [:update, :delete, :events]
  before_action :set_assoc, only: [:show, :edit, :update, :notifications, :members, :events, :delete, :pictures, :main_picture, :news]
  before_action :check_block, only: [:show, :edit, :update, :notifications, :members, :events, :delete, :pictures, :main_picture, :news]
  before_action :check_rights, only: [:update, :delete]

  swagger_api :index do
    summary "Get a list of all associations"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def index    
    query = "SELECT assocs.id, assocs.name, assocs.city, assocs.description, assocs.thumb_path, " +
      "(SELECT av_links.rights FROM av_links WHERE av_links.assoc_id=assocs.id " + 
      "AND av_links.volunteer_id=#{current_volunteer.id}) AS rights, " + 
      "(SELECT COUNT(*) FROM av_links WHERE av_links.assoc_id=assocs.id) AS nb_members, " +
      "(SELECT COUNT(*) FROM av_links INNER JOIN v_friends ON " +
      "av_links.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE assoc_id=assocs.id AND v_friends.volunteer_id=#{current_volunteer.id}) AS nb_friends_members" +
      " FROM assocs"
    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  swagger_api :create do
    summary "Allow volunteer to create an association"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :name, :string, :required, "Association's name"
    param :query, :description, :string, :required, "Association's description"
    param :query, :birthday, :date, :optional, "Date of creation"
    param :query, :city, :string,  :optional, "City where the association is located"
    param :query, :latitude, :decimal,  :optional, "Association latitude position"
    param :query, :longitude, :decimal,  :optional, "Association longitude position"    
    response :ok
    response 400
  end
  def create
    begin
      if Assoc.exist? assoc_params[:name]
        render :json => create_error(400, t("assocs.failure.name.unavailable"))
        return
      end
      new_assoc = Assoc.create!(assoc_params)
      
      link = AvLink.create!(assoc_id: new_assoc.id,
                            volunteer_id: current_volunteer.id, rights: 'owner')

      render :json => create_response(new_assoc.as_json.merge('rights' => 'owner'))
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  swagger_api :show do
    summary "Get associations information by its id"
    param :path, :id, :integer, :required, "Association's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def show
    link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: current_volunteer.id).first
    if link != nil
      render :json => create_response(@assoc.as_json.merge('rights' => link.rights)) and return
    end
    rights = nil

    notif = Notification.where(notif_type: 'InviteMember').where(assoc_id: @assoc.id)
      .where(receiver_id: current_volunteer.id).first
    if notif != nil
      rights = 'invited'
    end

    notif = Notification.where(notif_type: 'JoinAssoc').where(sender_id: current_volunteer.id)
      .where(assoc_id: @assoc.id).first
    if notif != nil
      rights = 'waiting'
    end
    
    render :json => create_response(@assoc.as_json.merge('rights' => rights)) and return
  end

  swagger_api :members do
    summary "Get a list of all members"
    param :path, :id, :integer, :required, "Association's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def members
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.email, volunteers.thumb_path, av_links.rights"
    render :json => create_response(Volunteer.joins(:av_links)
                                      .where(av_links: { assoc_id: @assoc.id })
                                      .select(query).limit(100))
  end

  swagger_api :events do
    summary "Get a list of all association's events"
    param :path, :id, :integer, :required, "Association's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def events
    privacy = ""
    if @link.eql?(nil)
      privacy = " AND events.private=false"
    end

    query = "SELECT events.id, events.title, events.place, events.begin, events.assoc_id, events.assoc_name, events.thumb_path, " +
      "(SELECT event_volunteers.rights FROM event_volunteers WHERE event_volunteers.event_id=" + 
      "events.id AND event_volunteers.volunteer_id=#{current_volunteer.id}) AS rights, " + 
      "(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest, " +
      "(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON " +
      "event_volunteers.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE event_id=events.id AND v_friends.volunteer_id=#{current_volunteer.id}) AS nb_friends_members" +
      " FROM events WHERE events.assoc_id=#{@assoc.id}" + privacy

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  swagger_api :update do
    summary "Update association"
    param :path, :id, :integer, :required, "Association's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :name, :string, :optional, "Association's name"
    param :query, :description, :string, :optional, "Association's description"
    param :query, :birthday, :date, :optional, "Date of creation"
    param :query, :city, :string,  :optional, "City where the association is located"
    param :query, :latitude, :decimal,  :optional, "Association latitude position"
    param :query, :longitude, :decimal,  :optional, "Association longitude position"    
    response :ok
    response 400
  end
  def update
    begin
      if !Assoc.is_new_name_available?(assoc_params[:name],
                                             @assoc.name)
        render :json => create_error(400, t("assocs.failure.name.unavailable"))
      elsif @assoc.update!(assoc_params)
        render :json => create_response(@assoc.as_json.merge('rights' => @link.rights))
      else
        render :json => create_error(400, t("assocs.failure.update"))
      end
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :delete do
    summary "Deletes association (needs to be owner)"
    param :path, :id, :integer, :required, "Association's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def delete
    if @link.rights.eql?('owner')
      Notification.where(assoc_id: @assoc.id).destroy_all
      AvLink.where(assoc_id: @assoc.id).destroy_all
      @assoc.destroy
      render :json => create_response(t("assocs.success.deleted")) and return
    end
    render :json => create_error(400, t("assocs.failure.rights"))    
  end

  swagger_api :invited do
    summary "Get all associations where you're invited"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def invited
    assocs = Assoc.select(:id, :name, :city, :thumb_path)
      .select("(SELECT COUNT(*) FROM av_links WHERE av_links.assoc_id=assocs.id) AS nb_members")
      .select("(SELECT COUNT(*) FROM av_links INNER JOIN v_friends ON av_links.volunteer_id=v_friends.friend_volunteer_id WHERE assoc_id=assocs.id AND v_friends.volunteer_id=#{current_volunteer.id}) AS nb_friends_members")
      .joins("INNER JOIN notifications ON notifications.assoc_id=assocs.id")
      .select("notifications.id AS notif_id")
      .where("notifications.receiver_id=#{current_volunteer.id} AND notifications.notif_type='InviteMember'")
    render :json => create_response(assocs)
  end

  swagger_api :pictures do
    summary "Returns a list of all association's pictures paths"
    param :path, :id, :integer, :required, "Association's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def pictures
    query = "id, file_size, picture_path, is_main"
    pictures = Picture.where(:assoc_id => @assoc.id).select(query).limit(100)
    render :json => create_response(pictures)
  end

  swagger_api :main_picture do
    summary "Returns path of main picture"
    param :path, :id, :integer, :required, "Association's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def main_picture
    query = "id, file_size, picture_path"
    pictures = Picture.where(:assoc_id => @assoc.id).where(:is_main => true).select(query).first
    render :json => create_response(pictures)
  end
  
  swagger_api :news do
    summary "Returns association's news"
    param :path, :id, :integer, :required, "Association's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    response :ok
    response 400
  end
  def news
    rights = current_volunteer.av_links.find_by(assoc_id: @assoc.id).try(:level)
    render json: create_response(@assoc.news.select { |new| (new.private and rights.present? and rights >= AvLink.levels["member"]) or new.public })
  end

  private
  def set_assoc
    begin
      @assoc = Assoc.find(params[:id])
    rescue
      render :json => create_error(400, t("assocs.failure.id"))
    end
  end

  def set_link
    @link = AvLink.where(:volunteer_id => current_volunteer.id).where(:assoc_id => @assoc.id).first
  end

  def assoc_params
    params.permit(:name, :description, :birthday, :city, :latitude, :longitude)
  end

  def check_block
    link = AvLink.where(volunteer_id: current_volunteer.id).where(assoc_id: @assoc.id).first
    if !link.eql?(nil) and link.level.eql?(AvLink.levels["block"])
      render :json => create_error(400, t("follower.failure.blocked"))      
    end
  end

  def check_rights
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("assocs.failure.rights"))
      return false
    end
    return true
  end
end
