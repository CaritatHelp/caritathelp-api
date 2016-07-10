class SheltersController < ApplicationController
  before_filter :check_token, except: [:index, :show, :search]
  before_action :set_volunteer, except: [:index, :show, :search]
  before_action :set_assoc, except: [:index, :show, :search, :pictures, :main_picture]
  before_action :set_shelter, only: [:show, :update, :delete, :pictures, :main_picture]
  before_action :check_rights, except: [:index, :show, :search, :pictures, :main_picture]

  def_param_group :shelter_create do
    param :token, String, "Creator's token", :required => true
    param :assoc_id, String, "Association's id", :required => true
    param :name, String, "Shelter's name", :required => true
    param :address, String, "Shelter's address", :required => true
    param :zipcode, Integer, "Shelter's zipcode", :required => true
    param :city, String, "Shelter's city", :required => true
    param :total_places, Integer, "Shelter's total places", :required => true
    param :free_places, Integer, "Shelter's free places", :required => true
    param :latitude, Float, "Shelter's latitude"
    param :longitude, Float, "Shelter's longitude"
    param :tags, String, "Shelter's tags"
  end
  
  def_param_group :shelter_update do
    param :token, String, "Creator's token", :required => true
    param :assoc_id, String, "Association's id", :required => true
    param :name, String, "Shelter's name"
    param :address, String, "Shelter's address"
    param :zipcode, Integer, "Shelter's zipcode"
    param :city, String, "Shelter's city"
    param :total_places, Integer, "Shelter's total places"
    param :free_places, Integer, "Shelter's free places"
    param :latitude, Float, "Shelter's latitude"
    param :longitude, Float, "Shelter's longitude"
    param :tags, String, "Shelter's tags"
  end
  
  api :GET, '/shelters', "Get a list of all existing shelters"
  example SampleJson.shelters('index')
  def index
    query = "id, name, address, zipcode, city, total_places, free_places, latitude, longitude, tags, thumb_path"
    render :json => create_response(Shelter.select(query).all)
  end
  
  api :POST, '/shelters', "Allow association to add a shelter"
  param_group :shelter_create
  example SampleJson.shelters('create')
  def create
    begin
      existing_shelter = Shelter.where(:name => shelter_params[:name])
        .where(:address => shelter_params[:address])
        .where(:zipcode => shelter_params[:zipcode])
        .first
      if existing_shelter.present?
        render :json => create_error(400, t("shelters.failure.exist")) and return        
      end

      new_shelter = Shelter.create!(shelter_params)
      render :json => create_response(new_shelter)
    rescue => e
      render :json => create_error(400, e.to_s) and return
    end
  end
  
  api :GET, '/shelters/:id', "Show information about the shelter refered by id"
  example SampleJson.shelters('show')
  def show    
    render :json => create_response(@shelter)
  end

  api :GET, '/shelters/search', "Search for shelter by its name, returns a list of matching shelters"
  param :research, String, "Shelter's name", :required => true
  example SampleJson.shelters('search')
  def search
    begin
      name = params[:research].downcase

      if name.length.eql?(0)
        render :json => create_error(400, t('shelters.failure.research')) and return        
      end
      query = "lower(name) LIKE ?"
      render :json => create_response(Shelter.select('id, name, city, total_places, free_places, thumb_path')
                                        .where(query, "#{name}%"))
    rescue => e
      render :json => create_error(400, t('shelters.failure.research')) and return
    end
  end

  api :PUT, '/shelters/:id', "Allow association to update the shelter refered by id"
  param_group :shelter_update
  example SampleJson.shelters('update')
  def update
    begin
      existing_shelter = Shelter.where(:name => shelter_params[:name])
        .where(:zipcode => @shelter.zipcode)
        .where(:city => @shelter.city)
        .where(:address => @shelter.address)
        .first
      if existing_shelter.present?
        render :json => create_error(400, t("shelters.failure.name")) and return        
      end
      @shelter.update!(shelter_params)
      render :json => create_response(@shelter)
    rescue => e
      render :json => create_error(400, e.to_s) and return
    end
  end
  
  api :DELETE, '/shelters/:id', "Allow association to delete a shelter"
  param :token, String, "Your token", :required => true
  param :assoc_id, String, "Association's id", :required => true
  example SampleJson.shelters('delete')
  def delete
    @shelter.destroy
    render :json => create_response(t("shelters.success.deleted"))
  end

  api :GET, '/shelters/:id/pictures', "Return a list of all shelter's pictures path"
  param :token, String, "Your token", :required => true
  example SampleJson.shelters('pictures')
  def pictures
    query = "id, file_size, picture_path, is_main"
    pictures = Picture.where(:shelter_id => @shelter.id).select(query).limit(100)
    render :json => create_response(pictures)
  end

  api :GET, '/shelters/:id/main_picture', "Return path of main picture"
  param :token, String, "Your token", :required => true
  example SampleJson.shelters('main_picture')
  def main_picture
    query = "id, file_size, picture_path"
    pictures = Picture.where(:shelter_id => @shelter.id).where(:is_main => true).select(query).first
    render :json => create_response(pictures)
  end
 
  private
  
  def shelter_params
    params = params.permit(:name, :address, :zipcode, :city, :total_places, :description,
                           :free_places, :tags, :latitude, :longitude, :tags => [])
    params[:assoc_id] = @assoc.id
    params
  end
  
  def set_volunteer
    @volunteer = Volunteer.find_by(token: params[:token])
  end
  
  def set_assoc
    begin
      @assoc = Assoc.find(params[:assoc_id])
    rescue
      render :json => create_error(400, t("assocs.failure.id"))
    end
  end

  def set_shelter
    begin
      @shelter = Shelter.find(params[:id])
    rescue
      render :json => create_error(400, t("shelters.failure.id"))
    end
  end
  
  def check_rights
    @link = AvLink.where(:volunteer_id => @volunteer.id).where(:assoc_id => @assoc.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("assocs.failure.rights")) and return
    end
  end
end
