class NewsController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_new, only: [:show, :comments]
  before_action :check_news_rights, only: [:show, :comments]

  api :GET, '/news', 'Get all news concerning the volunteer refered by the token'
  param :token, String, "Your token", :required => true
  example SampleJson.news('index')
  def index
    news = New::New.select("new_news.*, new_news.type AS news_type")
      .select("(SELECT title FROM events WHERE events.id=new_news.event_id) AS event_name")
      .select("(SELECT thumb_path FROM events WHERE events.id=new_news.event_id) AS event_thumb_path")
      .select("(SELECT name FROM assocs WHERE assocs.id=new_news.assoc_id) AS assoc_name")
      .select("(SELECT thumb_path FROM assocs WHERE assocs.id=new_news.assoc_id) AS assoc_thumb_path")
      .select("(SELECT fullname FROM volunteers WHERE volunteers.id=new_news.volunteer_id) AS volunteer_name")
      .select("(SELECT thumb_path FROM volunteers WHERE volunteers.id=new_news.volunteer_id) AS volunteer_thumb_path")
      .joins("LEFT JOIN event_volunteers ON new_news.event_id=event_volunteers.event_id")
      .joins("LEFT JOIN av_links ON new_news.assoc_id=av_links.assoc_id")
      .joins("LEFT JOIN v_friends ON new_news.volunteer_id=v_friends.friend_volunteer_id AND new_news.volunteer_id<>#{@volunteer.id} AND new_news.type='New::Volunteer::SelfWallMessage'")
      .where("(event_volunteers.volunteer_id=#{@volunteer.id} AND new_news.type<>'New::Event::MemberPublicWallMessage' AND event_volunteers.level>=#{EventVolunteer.levels['member']}) OR (av_links.volunteer_id=#{@volunteer.id} AND new_news.type<>'New::Assoc::MemberPublicWallMessage') OR (new_news.type='New::Volunteer::FriendWallMessage' AND new_news.friend_id=#{@volunteer.id}) OR (new_news.type='New::Volunteer::SelfWallMessage' AND (new_news.volunteer_id=#{@volunteer.id} OR v_friends.volunteer_id=#{@volunteer.id}))").order(updated_at: :desc)
    render :json => create_response(news)
  end

  api :POST, '/news/wall_message', "Create a wall message for yourself, friend, assoc or event"
  param :token, String, "Your token", :required => true
  param :content, String, "Content of status", :required => true
  param :friend_id, String, "Id of the friend you want to write on the wall"
  param :assoc_id, String, "Id of the association you want to write on the wall"
  param :event_id, String, "Id of the event you want to write on the wall"
  param :public, String, "Default: true. Set to false if you want the news to be visible only by members. (only for an event or association wall message)"
  example SampleJson.news('wall_message')
  def wall_message
    begin
      a = params.has_key?(:friend_id)
      b = params.has_key?(:assoc_id)
      c = params.has_key?(:event_id)
      is_public = true
      admin = false

      if params.has_key?(:private) and params[:private].eql?('true')
        is_public = false
      end

      if !((a and !b and !c) or (!a and b and !c) or (!a and !b and c) or (!a and !b and !c))
          render :json => create_error(400, t("news.failure.args")) and return
      end

      if params.has_key?(:friend_id) and params[:friend_id].to_i != @volunteer.id
        friend = Volunteer.find(params[:friend_id])
        link = VFriend.where(volunteer_id: @volunteer.id).where(friend_volunteer_id: friend.id).first
        if link.eql?(nil)
          render :json => create_error(400, t("news.failure.rights")) and return
        end
        wall_message = New::Volunteer::FriendWallMessage.create!(content: params[:content],
                                                                 volunteer_id: @volunteer.id,
                                                                 friend_id: friend.id)
      elsif params.has_key?(:assoc_id)
        assoc = Assoc.find(params[:assoc_id])
        link = AvLink.where(volunteer_id: @volunteer.id).where(assoc_id: assoc.id).first
        if link.eql?(nil)
          render :json => create_error(400, t("news.failure.rights")) and return
        end
        admin = true unless link.level < AvLink.levels["admin"]
        if !admin
          wall_message = New::Assoc::MemberPublicWallMessage.create!(content: params[:content],
                                                                     volunteer_id: @volunteer.id,
                                                                     assoc_id: assoc.id)
        elsif admin and is_public
          wall_message = New::Assoc::AdminPublicWallMessage.create!(content: params[:content],
                                                                    volunteer_id: @volunteer.id,
                                                                    assoc_id: assoc.id)
        else
          wall_message = New::Assoc::AdminPrivateWallMessage.create!(content: params[:content],
                                                                     volunteer_id: @volunteer.id,
                                                                     assoc_id: assoc.id,
                                                                     private: true)
        end
      elsif params.has_key?(:event_id)
        event = Event.find(params[:event_id])
        link = EventVolunteer.where(volunteer_id: @volunteer.id).where(event_id: event.id).first
        if link.eql?(nil)
          render :json => create_error(400, t("news.failure.rights")) and return
        end
        admin = true unless link.level < EventVolunteer.levels["admin"]
        if !admin
          wall_message = New::Event::MemberPublicWallMessage.create!(content: params[:content],
                                                                     volunteer_id: @volunteer.id,
                                                                     event_id: event.id)
        elsif admin and is_public
          wall_message = New::Event::AdminPublicWallMessage.create!(content: params[:content],
                                                                    volunteer_id: @volunteer.id,
                                                                    event_id: event.id)
        else
          wall_message = New::Event::AdminPrivateWallMessage.create!(content: params[:content],
                                                                     volunteer_id: @volunteer.id,
                                                                     event_id: event.id,
                                                                     private: true)
        end
      else
        wall_message = New::Volunteer::SelfWallMessage.create!(content: params[:content],
                                                               volunteer_id: @volunteer.id)
      end
      render :json => create_response(wall_message.as_json.merge('type' => wall_message.type))
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

  def check_news_rights
    begin
      if @new.volunteer_id.eql?(@volunteer.id)
        return true
      end
      
      if @new.private # Checking rights for a private news
        if @new.assoc_id != nil # private assoc news
          link = AvLink.where(assoc_id: @new.assoc_id).where(volunteer_id: @volunteer.id).first
          if !link.eql?(nil) and link.level >= AvLink.levels["member"]
            return true
          end
        elsif @new.event_id != nil # private event news
          link = EventVolunteer.where(event_id: @new.event_id)
            .where(volunteer_id: @volunteer.id).first
          if !link.eql?(nil) and link.level >= EventVolunteer.levels["member"]
            return true
          end
        else # private friend news
          link = VFriend.where(friend_volunteer_id: @new.volunteer_id)
            .where(volunteer_id: @volunteer.id).first
          if !link.eql?(nil)
            return true
          end
        end
      else # Checking rights for a public news
        if @new.assoc_id != nil # public assoc news
          return true
        elsif @new.event_id != nil # public event news
          p "LA??"
          event = Event.find(@new.event_id)
          event_link = EventVolunteer.where(event_id: @new.event_id)
            .where(volunteer_id: @volunteer.id).first

          if event.private # public news of a private event
            assoc_link = AvLink.where(assoc_id: event.assoc_id)
              .where(volunteer_id: @volunteer.id).first
            if !assoc_link.eql?(nil) and assoc_link.level >= AvLink.levels["member"]
              return true
            end
          else # public news of a public event
            return true
          end
        else # public friend news
          link = VFriend.where(friend_volunteer_id: @new.volunteer_id)
            .where(volunteer_id: @volunteer.id).first
          if !link.eql?(nil)
            return true
          end
        end
      end
      render :json => create_error(400, t("news.failure.rights"))
    rescue => e
      render :json => create_error(400, e.to_s)
    end
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
