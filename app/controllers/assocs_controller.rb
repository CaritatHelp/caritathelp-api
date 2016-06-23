class AssocsController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_assoc, only: [:show, :edit, :update, :notifications, :members, :events, :delete, :pictures, :main_picture, :news]
  before_action :check_rights, only: [:update, :delete]

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
    query = "SELECT assocs.id, assocs.name, assocs.city, assocs.description, assocs.thumb_path, " +
      "(SELECT av_links.rights FROM av_links WHERE av_links.assoc_id=assocs.id " + 
      "AND av_links.volunteer_id=#{@volunteer.id}) AS rights, " + 
      "(SELECT COUNT(*) FROM av_links WHERE av_links.assoc_id=assocs.id) AS nb_members, " +
      "(SELECT COUNT(*) FROM av_links INNER JOIN v_friends ON " +
      "av_links.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE assoc_id=assocs.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members" +
      " FROM assocs"
    render :json => create_response(ActiveRecord::Base.connection.execute(query))
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

      render :json => create_response(new_assoc.as_json.merge('rights' => 'owner'))
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
    if link != nil
      render :json => create_response(@assoc.as_json.merge('rights' => link.rights)) and return
    end
    rights = 'none'

    notif = Notification.where(notif_type: 'InviteMember').where(assoc_id: @assoc.id)
      .where(receiver_id: @volunteer.id).first
    if notif != nil
      rights = 'invited'
    end

    notif = Notification.where(notif_type: 'JoinAssoc').where(sender_id: @volunteer.id)
      .where(assoc_id: @assoc.id).first
    if notif != nil
      rights = 'waiting'
    end
    
    render :json => create_response(@assoc.as_json.merge('rights' => rights)) and return
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

  api :GET, '/associations/:id/members', 'Get a list of all members'
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('members')
  def members
    query = "volunteers.id, volunteers.firstname, volunteers.lastname, volunteers.mail, volunteers.thumb_path, av_links.rights"
    render :json => create_response(Volunteer.joins(:av_links)
                                      .where(av_links: { assoc_id: @assoc.id })
                                      .select(query).limit(100))
  end

  api :GET, '/associations/:id/events', "Get a list of all association's events"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('events')
  def events
    query = "SELECT events.id, events.title, events.place, events.begin, events.assoc_id, events.assoc_name, events.thumb_path, " +
      "(SELECT event_volunteers.rights FROM event_volunteers WHERE event_volunteers.event_id=" + 
      "events.id AND event_volunteers.volunteer_id=#{@volunteer.id}) AS rights, " + 
      "(SELECT COUNT(*) FROM event_volunteers WHERE event_volunteers.event_id=events.id) AS nb_guest, " +
      "(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON " +
      "event_volunteers.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members" +
      " FROM events WHERE events.assoc_id=#{@assoc.id}"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
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
        render :json => create_response(@assoc.as_json.merge('rights' => @link.rights))
      else
        render :json => create_error(400, t("assocs.failure.update"))
      end
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  
  api :DELETE, '/associations/:id', "Delete association (need to be owner)"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('delete')
  def delete
    if @link.rights.eql?('owner')
      Notification.where(assoc_id: @assoc.id).destroy_all
      AvLink.where(assoc_id: @assoc.id).destroy_all
      @assoc.destroy
      render :json => create_response(t("assocs.success.deleted")) and return
    end
    render :json => create_error(400, t("assocs.failure.rights"))    
  end

  api :GET, '/assocs/invited', "Get all assocs where you're invited"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('invited')
  def invited
    query = "SELECT assocs.id, assocs.name, assocs.city, assocs.thumb_path, " +
      "(SELECT COUNT(*) FROM av_links WHERE av_links.assoc_id=assocs.id) AS nb_members, " +
      "(SELECT COUNT(*) FROM av_links INNER JOIN v_friends ON " +
      "av_links.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE assoc_id=assocs.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members" +
      " FROM assocs INNER JOIN notifications " +
      "ON notifications.assoc_id=assocs.id " +
      "WHERE notifications.receiver_id=#{@volunteer.id} AND notifications.notif_type='InviteMember'"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  api :GET, '/associations/:id/pictures', "Return a list of all assoc's pictures path"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('pictures')
  def pictures
    query = "id, file_size, picture_path, is_main"
    pictures = Picture.where(:assoc_id => @assoc.id).select(query).limit(100)
    render :json => create_response(pictures)
  end

  api :GET, '/associations/:id/main_picture', "Return path of main picture"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('main_picture')
  def main_picture
    query = "id, file_size, picture_path"
    pictures = Picture.where(:assoc_id => @assoc.id).where(:is_main => true).select(query).first
    render :json => create_response(pictures)
  end
  
  api :GET, '/associations/:id/news', "Get associations's news"
  param :token, String, "Your token", :required => true
  example SampleJson.assocs('news')
  def news
    query = "SELECT id, type, assoc_id, title, content " +
      "FROM new_news WHERE new_news.assoc_id=#{@assoc.id}"
    render :json => create_response(ActiveRecord::Base.connection.execute(query))
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
