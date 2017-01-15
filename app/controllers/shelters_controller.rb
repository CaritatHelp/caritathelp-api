class SheltersController < ApplicationController
  swagger_controller :shelters, "Shelters management"

  before_action :authenticate_volunteer!,
                except: [:index, :show, :search, :pictures, :main_picture],
                unless: :is_swagger_request?

  before_action :set_assoc, except: [:index, :show, :search, :pictures, :main_picture]
  before_action :set_shelter, only: [:show, :update, :delete, :pictures, :main_picture]
  before_action :check_rights, except: [:index, :show, :search, :pictures, :main_picture]

  swagger_api :index do
    summary "Get a list of all existing shelters"
    response :ok
  end
  def index
    query = "id, name, address, zipcode, city, total_places, free_places, latitude, longitude, tags, thumb_path"
    render :json => create_response(Shelter.select(query).all)
  end

  swagger_api :create do
    summary "Allow an association to add a shelter"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id"
    param :query, :name, :string, :required, "Shelter's name"
    param :query, :address, :string, :required, "Shelter's address"
    param :query, :zipcode, :integer, :required, "Shelter's zipcode"
    param :query, :city, :string, :required, "Shelter's city"
    param :query, :total_places, :integer, :required, "Shelter's total places"
    param :query, :free_places, :integer, :required, "Shelter's free places"
    param :query, :description, :string, :optional, "Shelter's description"
    param :query, :phone, :string, :optional, "Shelter's phone number"
    param :query, :mail, :string, :optional, "Shelter's mail"
    param :query, :latitude, :decimal, :optional, "Shelter's latitude"
    param :query, :longitude, :decimal, :optional, "Shelter's longitude"
    param :query, :tags, :string, :optional, "Shelter's tags"
    response :ok
  end
  def create
    begin
      existing_shelter = Shelter.where(:name => shelter_params[:name])
        .where(:address => shelter_params[:address])
        .where(:zipcode => shelter_params[:zipcode])
        .first
      if existing_shelter.present?
        render :json => create_error(400, t("shelters.failure.exist")) and return
      end

      new_shelter = Shelter.new(shelter_params)
      if new_shelter.save
	      render :json => create_response(new_shelter)
      else
	      render :json => create_error(400, new_shelter.errors.full_messages.to_sentence) and return
      end
    rescue => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :show do
    summary "Get a list of all existing shelters"
    param :path, :id, :integer, :required, "Shelter's id"
    response :ok
  end
  def show
    render :json => create_response(@shelter)
  end

  swagger_api :search do
    summary "Search for shelter by its name, returns a list of shelters"
    param :query, :research, :string, :required, "Shelter's name"
    response :ok
  end
  def search
    begin
      name = params[:research].downcase

      if name.length.eql?(0)
        render :json => create_error(400, t('shelters.failure.research')) and return
      end
      query = "lower(name) LIKE ?"
      render :json => create_response(Shelter.select('id, name, city, total_places, free_places, thumb_path')
                                        .where(query, "%#{name}%"))
    rescue => e
      render :json => create_error(400, t('shelters.failure.research')) and return
    end
  end

  swagger_api :update do
    summary "Allow association to update shelter"
    param :path, :id, :integer, :required, "Shelter's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id"
    param :query, :name, :string, :optional, "Shelter's name"
    param :query, :address, :string, :optional, "Shelter's address"
    param :query, :zipcode, :integer, :optional, "Shelter's zipcode"
    param :query, :city, :string, :optional, "Shelter's city"
    param :query, :total_places, :integer, :optional, "Shelter's total places"
    param :query, :free_places, :integer, :optional, "Shelter's free places"
    param :query, :description, :string, :optional, "Shelter's description"
    param :query, :phone, :string, :optional, "Shelter's phone number"
    param :query, :mail, :string, :optional, "Shelter's mail"
    param :query, :latitude, :decimal, :optional, "Shelter's latitude"
    param :query, :longitude, :decimal, :optional, "Shelter's longitude"
    param :query, :tags, :string, :optional, "Shelter's tags"
    response :ok
  end
  def update
    begin
      existing_shelter = Shelter.where(:name => shelter_params[:name])
        .where(:zipcode => @shelter.zipcode)
        .where(:city => @shelter.city)
        .where(:address => @shelter.address)
        .first
      if existing_shelter.present? and existing_shelter.id != @shelter.id
        render :json => create_error(400, t("shelters.failure.name")) and return
      end
      @shelter.update!(shelter_params)
      render :json => create_response(@shelter)
    rescue => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :delete do
    summary "Allow association to delete a shelter"
    param :path, :id, :integer, :required, "Shelter's id"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id"
    response :ok
  end
  def delete
    @shelter.destroy
    render :json => create_response(t("shelters.success.deleted"))
  end

  swagger_api :pictures do
    summary "Returns a list of all shelter's pictures path"
    param :path, :id, :integer, :required, "Shelter's id"
    response :ok
  end
  def pictures
    query = "id, file_size, picture_path, is_main"
    pictures = Picture.where(:shelter_id => @shelter.id).select(query).limit(100)
    render :json => create_response(pictures)
  end

  swagger_api :main_picture do
    summary "Returns path of main picture"
    param :path, :id, :integer, :required, "Shelter's id"
    response :ok
  end
  def main_picture
    query = "id, file_size, picture_path"
    pictures = Picture.where(:shelter_id => @shelter.id).where(:is_main => true).select(query).first
    render :json => create_response(pictures)
  end

  private

  def shelter_params
    params_shelter = params.permit(:name, :address, :zipcode, :city, :total_places, :description,
                                   :free_places, :tags, :phone, :mail, :latitude, :longitude,
                                   :tags => [])
    params_shelter[:assoc_id] = @assoc.id
    params_shelter
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
    @link = AvLink.where(:volunteer_id => current_volunteer.id).where(:assoc_id => @assoc.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("assocs.failure.rights")) and return
    end
  end
end
