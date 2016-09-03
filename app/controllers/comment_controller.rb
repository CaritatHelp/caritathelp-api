class CommentController < ApplicationController
  swagger_controller :comments, "Comments management"

  before_filter :check_token
  before_action :set_volunteer
  before_action :set_new, only: [:create]
  before_action :set_comment, only: [:update, :delete, :show]
  before_action :check_rights

  swagger_api :create do
    summary "Creates a comment linked to the new"
    param :query, :token, :string, :required, "Your token"
    param :query, :content, :string, :required, "Content of the comment"
    param :query, :new_id, :integer, :required, "New's id"
    response :ok
    response 400
  end
  def create
    begin
      new_comment = Comment.create!([new_id: @new.id, volunteer_id: @volunteer.id,
                                     content: params[:content]]).first
      render :json => create_response(new_comment.as_json.merge(
                                       thumb_path: @volunteer.thumb_path,
                                       firstname: @volunteer.firstname,
                                       lastname: @volunteer.lastname))
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :update do
    summary "Update the comment referred by id"
    param :path, :id, :integer, :required, "Comment's id"
    param :query, :token, :string, :required, "Your token"
    param :query, :content, :string, :required, "Content of the comment"
    response :ok
    response 400
  end
  def update
    begin
      if @comment.volunteer_id != @volunteer.id
        render :json => create_error(400, t("comments.failure.rights")) and return        
      end
      # changer le permit
      @comment.update!(params.permit(:content))
      render :json => create_response(@comment.as_json.merge(thumb_path: @volunteer.thumb_path))
    rescue Exception => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :show do
    summary "Returns the comment's information"
    param :path, :id, :integer, :required, "Comment's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
    response 400
  end
  def show
    render :json => create_response(@comment)
  end

  swagger_api :delete do
    summary "Delete the comment"
    param :path, :id, :integer, :required, "Comment's id"
    param :query, :token, :string, :required, "Your token"
    response :ok
    response 400
  end
  def delete
    # permettre au owner d'une actu de delete un comment
    if @comment.volunteer_id != @volunteer.id
      render :json => create_error(400, t("comments.failure.rights")) and return        
    end
    @comment.destroy
    render :json => create_response(t("comments.success.deleted"))
  end

  private
  def set_volunteer
    @volunteer = Volunteer.find_by(token: params[:token])
  end

  def set_comment
    begin
      @comment = Comment.find(params[:id])
      @new = New::New.find(@comment.new_id)
    rescue
      render :json => create_error(400, t("comments.failure.id"))
    end
  end

  def set_new
    begin
      @new = New::New.find(params[:new_id])
    rescue
      render :json => create_error(400, t("news.failure.id"))
    end
  end

  def check_rights
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
      render :json => create_error(400, t("comments.failure.rights"))
    rescue => e
      render :json => create_error(400, e.to_s)
    end    
  end
end
