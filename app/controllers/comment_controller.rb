class CommentController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_new, only: [:create]
  before_action :set_comment, only: [:update, :delete, :show]
  before_action :check_rights, only: [:create]

  api :POST, '/comments', 'Create a comment linked to the new'
  param :token, String, "Your token", :required => true
  param :content, String, "Content of comment", :required => true
  param :new_id, String, "Id of the new", :required => true
  example SampleJson.comments('create')
  def create
    begin
      new_comment = Comment.create!([new_id: @new.id, volunteer_id: @volunteer.id,
                                     content: params[:content]]).first
      render :json => create_response(new_comment)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :PUT, '/comments/:id', 'Update the comment referred by id'
  param :token, String, "Your token", :required => true
  param :content, String, "Content of comment", :required => true
  example SampleJson.comments('update')
  def update
    begin
      if @comment.volunteer_id != @volunteer.id
        render :json => create_error(400, t("comments.failure.rights")) and return        
      end
      # changer le permit
      @comment.update!(params.permit(:content))
      render :json => create_response(@comment.complete_description)
    rescue Exception => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :GET, '/comments/:id', 'Get the comment'
  param :token, String, "Your token", :required => true
  example SampleJson.comments('show')
  def show
    render :json => create_response(@comment.complete_description)
  end

  api :DELETE, '/comments/:id', 'Get the comment'
  param :token, String, "Your token", :required => true
  example SampleJson.comments('delete')
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
    # can't put several conditions on multiples lines? SyntaxError
    is_assoc_concerned = (!@new.assoc_id.eql?(nil) && AvLink.where(assoc_id: @new.assoc_id).where(volunteer_id: @volunteer.id).present?)
    is_event_concerned = (!@new.event_id.eql?(nil) && EventVolunteer.where(event_id: @new.event_id).where(volunteer_id: @volunteer.id).present?)
    is_friend_concerned = (!@new.volunteer_id.eql?(nil) && VFriend.where(friend_volunteer_id: @new.volunteer_id).where(volunteer_id: @volunteer.id).present?)
    is_himself = @new.volunteer_id.eql?(@volunteer.id)
    
    if is_assoc_concerned or is_event_concerned or is_friend_concerned or is_himself
      return true
    end
    render :json => create_error(400, t("comments.failure.rights"))
    return false
  end
end
