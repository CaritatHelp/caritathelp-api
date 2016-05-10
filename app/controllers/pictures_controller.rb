class PicturesController < ApplicationController
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_picture, only: [:delete, :update]
  before_action :check_rights, only: [:create]

  def_param_group :upload do
    param :token, String, "Your token", :required => true
    param :file, String, "File content, IMPORTANT : need to be encoded in base64", :required => true
    param :filename, String, "Name to give to the file", :required => true
    param :original_filename, String, "Original name of the file", :required => true
    param :assoc_id, Integer, "Id of the assoc, if the picture is about an assoc"
    param :event_id, Integer, "Id of the event, if the picture is about an event"
    param :is_main, String, "True to make it the main picture of your profile/event. Will be automatically set to true if it's the first picture to be upload, and to false otherwise"
  end

  api :POST, '/pictures', "Upload a picture on the server"
  param_group :upload
  example SampleJson.pictures('create')
  def create
    #check if file is within picture_path
    actual_params = Hash.new
    actual_params[:picture] = Hash.new
    actual_params[:picture][:picture_path] = Hash.new
    actual_params[:picture][:picture_path][:file] = picture_params[:file]
    actual_params[:picture][:picture_path][:filename] = picture_params[:filename]
    actual_params[:picture][:picture_path][:original_filename] = picture_params[:original_filename]
    actual_params[:picture][:is_main] = picture_params[:is_main]
    actual_params[:picture][:event_id] = picture_params[:event_id]
    actual_params[:picture][:assoc_id] = picture_params[:assoc_id]

    if actual_params[:picture][:picture_path][:file]
      picture_path_params = actual_params[:picture][:picture_path]

      #create a new tempfile named fileupload
      tempfile = Tempfile.new("fileupload")
      tempfile.binmode

      #get the file and decode it with base64 then write it to the tempfile
      tempfile.write(Base64.decode64(picture_path_params[:file]))

      #create a new uploaded file
      uploaded_file = ActionDispatch::Http::UploadedFile
        .new(:tempfile => tempfile,
             :filename => picture_path_params[:filename],
             :original_filename => picture_path_params[:original_filename])

      #replace picture_path with the new uploaded file
      actual_params[:picture][:picture_path] =  uploaded_file
      actual_params[:picture][:volunteer_id] = @volunteer.id

      # this section make sure that there's at least and only one main picture
      current_main_picture = nil
      if @event != nil
        current_main_picture = Picture.where(:volunteer_id => @volunteer.id).where(:event_id => @event.id)
          .where(:is_main => true).first
      elsif @assoc != nil
        current_main_picture = Picture.where(:volunteer_id => @volunteer.id).where(:assoc_id => @assoc.id)
          .where(:is_main => true).first
      else
        current_main_picture = Picture.where(:volunteer_id => @volunteer.id).where(:assoc_id => nil)
          .where(:event_id => nil).where(:is_main => true).first
      end
      if !current_main_picture.eql?(nil) && actual_params[:picture][:is_main] == "true"
        begin
          current_main_picture.is_main = false
          current_main_picture.save!
        rescue
          render :json => create_error(400, t("pictures.failure.is_main")), status: 400
        end
      elsif current_main_picture.eql?(nil)
        actual_params[:picture][:is_main] = true
      else
        actual_params[:picture][:is_main] = false
      end
    end
    
    begin
      @picture = Picture.create!(actual_params[:picture])
      render :json => create_response(@picture)
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s), status: 400
    end
  end
  
  
  api :DELETE, '/pictures/:id', "Delete the picture referred by id, if it's not the main picture"
  param :token, String, "Your token", :required => true
  example SampleJson.pictures('delete')
  def delete
    if @current_picture.event_id.eql?(nil) and @current_picture.assoc_id.eql?(nil) and @current_picture.volunteer_id != @volunteer.id
      render :json => create_error(400, t("pictures.failure.rights")), status: 400 and return
    elsif @current_picture.event_id != nil
      link = EventVolunteer.where(:event_id => @current_picture.event_id)
        .where(:volunteer_id => @volunteer.id).first
      if link.eql?(nil) or link.rights.eql?("guest")
        render :json => create_error(400, t("pictures.failure.rights")), status: 400 and return
      end
    elsif @current_picture.assoc_id != nil
      link = AvLink.where(:assoc_id => @current_picture.assoc_id)
        .where(:volunteer_id => @volunteer.id).first
      if link.eql?(nil) or link.rights.eql?("member")
        render :json => create_error(400, t("pictures.failure.rights")), status: 400 and return
      end
    end
    if @current_picture.is_main
      render :json => create_error(400, t("pictures.failure.not_deleted")), status: 400
    else
      @current_picture.destroy
      render :json => create_response(t("pictures.success.deleted"))
    end
  end

  api :PUT, '/pictures/:id', "Set the picture referred by id as the main picture"
  param :token, String, "Your token", :required => true
  example SampleJson.pictures('update')
  def update
    if @current_picture.event_id.eql?(nil) and @current_picture.assoc_id.eql?(nil) and @current_picture.volunteer_id != @volunteer.id
      render :json => create_error(400, t("pictures.failure.rights")), status: 400 and return
    elsif @current_picture.event_id != nil
      link = EventVolunteer.where(:event_id => @current_picture.event_id)
        .where(:volunteer_id => @volunteer.id).first
      if link.eql?(nil) or link.rights.eql?("guest")
        render :json => create_error(400, t("pictures.failure.rights")), status: 400 and return
      end
    elsif @current_picture.assoc_id != nil
      link = AvLink.where(:assoc_id => @current_picture.assoc_id)
        .where(:volunteer_id => @volunteer.id).first
      if link.eql?(nil) or link.rights.eql?("member")
        render :json => create_error(400, t("pictures.failure.rights")), status: 400 and return
      end
    end

    begin
      # downgrade the actual main picture
      if @current_picture.event_id != nil
        current_main_picture = Picture.where(:event_id => @current_picture.event_id)
          .where(:is_main => true).first
      elsif @current_picture.assoc_id != nil
        current_main_picture = Picture.where(:assoc_id => @current_picture.assoc_id)
          .where(:is_main => true).first
      else
        current_main_picture = Picture.where(:volunteer_id => @volunteer.id).where(:event_id => nil)
          .where(:assoc_id => nil).where(:is_main => true).first
      end
      if !current_main_picture.eql?(nil)
        current_main_picture.is_main = false
        current_main_picture.save!
      end
      
      @current_picture.update!({:is_main => true})
      
      render :json => create_response(@current_picture)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      render :json => create_error(400, e.to_s), status: 400 and return
    end
  end

  private
  def picture_params
    params.permit(:is_main, :event_id, :assoc_id, :file, :filename, :original_filename)
  end

  def set_volunteer
    @volunteer = Volunteer.find_by(token: params[:token])
  end

  def set_picture
    begin
      @current_picture = Picture.find(params[:id])
    rescue
      render :json => create_error(400, t("pictures.failure.id")), status: 400 and return
    end
  end

  def check_rights
    if params[:event_id] == nil and params[:assoc_id] == nil
      return true
    elsif params[:event_id] != nil and params[:assoc_id] != nil
      render :json => create_error(400, t("pictures.failure.specify")), status: 400
      return false
    elsif params[:event_id] != nil
      begin
        @event = Event.find(params[:event_id])
        @link = EventVolunteer.where(:volunteer_id => @volunteer.id)
          .where(:event_id => @event.id).first
        
        if @link.eql?(nil) or @link.rights.eql?('guest')
          render :json => create_error(400, t("events.failure.rights")), status: 400
          return false
        end
        return true
      rescue
        render :json => create_error(400, t("events.failure.id")), status: 400
      end
    elsif params[:assoc_id] != nil
      begin
        @assoc = Assoc.find(params[:assoc_id])
        @link = AvLink.where(:volunteer_id => @volunteer.id)
          .where(:assoc_id => @assoc.id).first
        
        if @link.eql?(nil) or @link.rights.eql?('member')
          render :json => create_error(400, t("assocs.failure.rights")), status: 400
          return false
        end
        return true
      rescue
        render :json => create_error(400, t("assocs.failure.id")), status: 400
      end      
    end
  end
end
