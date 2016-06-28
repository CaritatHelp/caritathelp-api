class NewsController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_new, only: [:show, :comments]
  before_action :set_assoc, only: [:assoc_status]
  before_action :set_event, only: [:event_status]
  before_action :check_assoc_rights, only: [:assoc_status]
  before_action :check_event_rights, only: [:event_status]

  api :GET, '/news', 'Get all news concerning the volunteer refered by the token'
  param :token, String, "Your token", :required => true
  example SampleJson.news('index')
  def index
    news = New::New.select("new_news.*, new_news.type AS notif_type")
      .select("(SELECT title FROM events WHERE events.id=new_news.event_id) AS event_name")
      .select("(SELECT thumb_path FROM events WHERE events.id=new_news.event_id) AS event_thumb_path")
      .select("(SELECT name FROM assocs WHERE assocs.id=new_news.assoc_id) AS assoc_name")
      .select("(SELECT thumb_path FROM assocs WHERE assocs.id=new_news.assoc_id) AS assoc_thumb_path")
      .select("(SELECT fullname FROM volunteers WHERE volunteers.id=new_news.volunteer_id) AS volunteer_name")
      .select("(SELECT thumb_path FROM volunteers WHERE volunteers.id=new_news.volunteer_id) AS volunteer_thumb_path")
      .joins("LEFT JOIN event_volunteers ON new_news.event_id=event_volunteers.event_id")
      .joins("LEFT JOIN av_links ON new_news.assoc_id=av_links.assoc_id")
      .joins("LEFT JOIN v_friends ON new_news.volunteer_id=v_friends.volunteer_id AND new_news.volunteer_id<>#{@volunteer.id}")
      .where("event_volunteers.volunteer_id=#{@volunteer.id} OR av_links.volunteer_id=#{@volunteer.id} OR v_friends.friend_volunteer_id=#{@volunteer.id} OR new_news.volunteer_id=#{@volunteer.id}")
    
    
    render :json => create_response(news)
    # query = "(SELECT new_news.*, (SELECT title FROM events WHERE events.id=new_news.event_id) AS sender_name " +
    #   "FROM new_news INNER JOIN event_volunteers ON new_news.event_id=event_volunteers.event_id WHERE event_volunteers.volunteer_id = #{@volunteer.id}) UNION " +
    #   "(SELECT new_news.*, (SELECT fullname FROM volunteers WHERE volunteers.id=new_news.volunteer_id) AS sender_name " +
    #   "FROM new_news INNER JOIN v_friends ON new_news.volunteer_id=v_friends.volunteer_id WHERE v_friends.friend_volunteer_id = #{@volunteer.id}) UNION " +
    #   "(SELECT new_news.*, (SELECT name FROM assocs WHERE assocs.id=new_news.assoc_id) AS sender_name " +
    #   "FROM new_news INNER JOIN av_links ON new_news.assoc_id=av_links.assoc_id WHERE av_links.volunteer_id = #{@volunteer.id}) UNION " +
    #   "(SELECT new_news.*, (SELECT fullname FROM volunteers WHERE volunteers.id=new_news.volunteer_id) AS sender_name " +
    #   "FROM new_news WHERE new_news.volunteer_id=#{@volunteer.id})"

    # render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  api :POST, '/news/volunteer_status', 'Create a new status for the volunteer'
  param :token, String, "Your token", :required => true
  param :content, String, "Content of status", :required => true
  example SampleJson.news('volunteer_status')
  def volunteer_status
    begin
      new_status = New::Volunteer::Status.create!(content: params[:content],
                                                  volunteer_id: @volunteer.id)
      render :json => create_response(new_status.as_json.merge('type' => new_status.type))
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :POST, '/news/assoc_status', 'Create a new status for the assoc'
  param :token, String, "Your token", :required => true
  param :content, String, "Content of status", :required => true
  param :assoc_id, String, "Id of the assoc writing the new status", :required => true
  example SampleJson.news('assoc_status')
  def assoc_status
    begin
      new_status = New::Assoc::Status.create!(content: params[:content],
                                              assoc_id: @assoc.id)
      render :json => create_response(new_status.as_json.merge('type' => new_status.type))
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :POST, '/news/event_status', 'Create a new status for the event'
  param :token, String, "Your token", :required => true
  param :content, String, "Content of status", :required => true
  param :event_id, String, "Id of the event writing the new status", :required => true
  example SampleJson.news('event_status')
  def event_status
    begin
      new_status = New::Event::Status.create!(content: params[:content],
                                              event_id: @event.id)
      render :json => create_response(new_status.as_json.merge('type' => new_status.type))
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :GET, '/news/:id', 'Get information of the new'
  param :token, String, "Your token", :required => true
  example SampleJson.news('show')
  def show
    infos = Assoc.where(id: @new.assoc_id).select('name, thumb_path').first unless @new.assoc_id.nil?
    infos = Event.where(id: @new.event_id).select('title, thumb_path').first unless @new.event_id.nil?
    infos = Volunteer.where(id: @new.volunteer_id).select('fullname, thumb_path').first unless @new.volunteer_id.nil?
    name = infos['name'] unless @new.assoc_id.nil?
    name = infos['title'] unless @new.event_id.nil?
    name = infos['fullname'] unless @new.volunteer_id.nil?
    render :json => create_response(@new.as_json.merge(sender_name: name, thumb_path: infos['thumb_path'], type: @new.type))
  end

  api :GET, '/news/:id/comments', 'Get comments of the new'
  param :token, String, "Your token", :required => true
  example SampleJson.news('comments')
  def comments
    render :json => create_response(Comment
                                      .joins('INNER JOIN volunteers ON comments.volunteer_id=volunteers.id')
                                      .where(new_id: @new.id)
                                      .select('comments.*', :firstname, :lastname, :thumb_path))
  end

  private
  def set_event
    begin
      @event = Event.find(params[:event_id])
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

  def set_new
    begin
      @new = New::New.find(params[:id])
    rescue
      render :json => create_error(400, t("news.failure.id"))
    end
  end

  def set_volunteer
    @volunteer = Volunteer.find_by(token: params[:token])
  end

  def check_event_rights
    @link = EventVolunteer.where(:volunteer_id => @volunteer.id)
      .where(:event_id => @event.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("events.failure.rights"))
      return false
    end
    return true
  end
  
  def check_assoc_rights
    @link = AvLink.where(:volunteer_id => @volunteer.id)
      .where(:assoc_id => @assoc.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("assocs.failure.rights"))
      return false
    end
    return true
  end
  
end
