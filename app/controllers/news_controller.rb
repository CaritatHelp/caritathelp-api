class NewsController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_assoc, only: [:assoc_status]
  before_action :set_event, only: [:event_status]
  before_action :check_assoc_rights, only: [:assoc_status]
  before_action :check_event_rights, only: [:event_status]

  api :GET, '/news', 'Get all news concerning the volunteer refered by the token'
  param :token, String, "Your token", :required => true
  example SampleJson.news('index')
  def index
    # query = "((event_id = 1) AND (EXISTS(SELECT * FROM event_volunteers WHERE ((event_id = 1) AND (volunteer_id = ?)))))"
    # news = New::New.joins(:event_volunteers).where(event_volunteers: { volunteer_id: @volunteer.id }).all.map(&:complete_description)
    # news = New::New.where(query, @volunteer.id).map(&:complete_description)

    fields = "new_news.type, new_news.id, new_news.assoc_id, new_news.event_id, new_news.volunteer_id, new_news.content"

    query = "(SELECT " + fields + " FROM new_news INNER JOIN event_volunteers ON new_news.event_id=event_volunteers.event_id WHERE event_volunteers.volunteer_id = ?) UNION " +
      "(SELECT " + fields + " FROM new_news INNER JOIN v_friends ON new_news.volunteer_id=v_friends.current_volunteer_id WHERE v_friends.friend_volunteer_id = ?) UNION " +
      "(SELECT " + fields + " FROM new_news INNER JOIN av_links ON new_news.assoc_id=av_links.assoc_id WHERE av_links.volunteer_id = ?)"

    news = New::New.find_by_sql([query, @volunteer.id, @volunteer.id, @volunteer.id]).map(&:complete_description)
    render :json => create_response({'news' => news})
  end

  api :POST, '/news/volunteer_status', 'Create a new status for the volunteer'
  param :token, String, "Your token", :required => true
  param :content, String, "Content of status", :required => true
  example SampleJson.news('volunteer_status')
  def volunteer_status
    begin
      new_status = New::Volunteer::Status.create!(content: params[:content],
                                                  volunteer_id: @volunteer.id)
      render :json => create_response(new_status.complete_description)
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
      render :json => create_response(new_status.complete_description)
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
      render :json => create_response(new_status.complete_description)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render :json => create_error(400, e.to_s) and return
    end
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
