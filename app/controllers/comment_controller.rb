class CommentController < ApplicationController
  swagger_controller :comments, "Comments management"

  before_action :authenticate_volunteer!, unless: :is_swagger_request?

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
      new_comment = Comment.create!([new_id: @new.id, volunteer_id: current_volunteer.id,
                                     content: params[:content]]).first
      render :json => create_response(new_comment.as_json.merge(
                                       thumb_path: current_volunteer.thumb_path,
                                       firstname: current_volunteer.firstname,
                                       lastname: current_volunteer.lastname))
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
      if @comment.volunteer_id != current_volunteer.id
        render :json => create_error(400, t("comments.failure.rights")) and return        
      end
      # changer le permit
      @comment.update!(params.permit(:content))
      render :json => create_response(@comment.as_json.merge(thumb_path: current_volunteer.thumb_path))
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
    if @comment.volunteer_id != current_volunteer.id
      render :json => create_error(400, t("comments.failure.rights")) and return        
    end
    @comment.destroy
    render :json => create_response(t("comments.success.deleted"))
  end

  private
  def set_comment
    begin
      @comment = Comment.find(params[:id])
      @new = New.find(@comment.new_id)
    rescue
      render :json => create_error(400, t("comments.failure.id"))
    end
  end

  def set_new
    begin
      @new = New.find(params[:new_id])
    rescue
      render :json => create_error(400, t("news.failure.id"))
    end
  end

  def check_rights
    if @new.private
      level = current_volunteer.av_links.find_by(assoc_id: @new.group_id).try(:level) if @new.group_type == "Assoc"
      level = current_volunteer.event_volunteers.find_by(event_id: @new.group_id).try(:level) if @new.group_type == "Event"
      if ((@new.group_type == "Assoc" and (level.blank? or level < AvLink.levels["member"])) || (@new.group_type == "Event" and (level.blank? or level < EventVolunteer.levels["member"])) || (@new.group_type == "Volunteer" and current_volunteer.v_friends.find_by(friend_volunteer_id: @new.group_id)))
        render json: create_error(400, t("volunteers.failure.rights"))
      end
    end
  end
end
