# -*- coding: utf-8 -*-
class VolunteersController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:create, :destroy]
  before_filter :check_token, except: [:create, :destroy]
  before_action :set_volunteer, only: [:show, :edit, :update, :destroy, :friends, :notifications, :associations, :events]
  before_action :set_current_volunteer, only: [:index]

  def_param_group :volunteers_creation do
    param :mail, String, "Your mail address", :required => true
    param :password, String, "Chosen password, must contain letters and numbers", :required => true
    param :firstname, String, "Your firstname", :required => true
    param :lastname, String, "Your lastname", :required => true
    param :birthday, Date, "Your birthday"
    param :gender, String, "Must be 'm' or 'f'"
    param :city, String, "Your current city"
    param :latitude, Float, "Latitude position"
    param :longitude, Float, "Longitude position"
    param :allowgps, String, "Must be 'true' or 'false' for allowing geolocalisation"
    param :allow_notifications, String, "Must be 'true' or 'false' for allowing notifications"
  end

  def_param_group :volunteers_update do
    param :token, String, "Your token", :required => true
    param :mail, String, "Your mail address"
    param :password, String, "Chosen password, must contain letters and numbers"
    param :firstname, String, "Your firstname"
    param :lastname, String, "Your lastname"
    param :birthday, Date, "Your birthday"
    param :gender, String, "Must be 'm' or 'f'"
    param :city, String, "Your current city"
    param :latitude, Float, "Latitude position"
    param :longitude, Float, "Longitude position"
    param :allowgps, String, "Must be 'true' or 'false' for allowing geolocalisation"
    param :allow_notifications, String, "Must be 'true' or 'false' for allowing notifications"
  end
  
  api :GET, '/volunteers', "Get a list of all volunteers"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('index')
  def index
    query = "SELECT volunteers.id, mail, firstname, lastname, birthday, gender, " +
      "city, latitude, longitude, allowgps, allow_notifications, " +
      "(SELECT COUNT(*) FROM v_friends AS link INNER JOIN v_friends " +
      "ON link.friend_volunteer_id=v_friends.friend_volunteer_id WHERE " +
      "link.volunteer_id=#{@current_volunteer.id} AND " +
      "v_friends.volunteer_id=volunteers.id AND " +
      "v_friends.volunteer_id<>#{@current_volunteer.id}) AS nb_common_friends FROM volunteers"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  api :POST, '/volunteers', "Allow volunteer to create an account"
  param_group :volunteers_creation
  example SampleJson.volunteers('create')
  def create
    begin
      if Volunteer.exist? volunteer_params[:mail]
        render :json => create_error(400, t("volunteers.failure.mail.unavailable"))
        return
      end
      new_volunteer = Volunteer.create!(volunteer_params)
      render :json => create_response(new_volunteer.complete_description)
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  api :GET, '/volunteers/:id', "Get volunteer informations by its id"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('show')
  def show
    render :json => create_response(@volunteer.simple_description)
  end

  api :GET, '/volunteers/search', "Search for volunteer by its firstname and/or lastname, return a list of matching volunteers"
  param :token, String, "Your token", :required => true
  param :research, String, "Volunteer firtname and/or lastname", :required => true
  example SampleJson.volunteers('search')
  def search
    begin
      words = params[:research].split(/\W+/)
      if words.size > 1
        condition = "(lower(firstname) LIKE ? AND lower(lastname) LIKE ?) OR (lower(firstname) LIKE ? AND lower(lastname) LIKE ?)"
        render :json => create_response(Volunteer.select('id, mail, firstname, lastname, birthday, gender, city')
                                          .where(condition,
                                                 "#{words[0].downcase}%",
                                                 "#{words[1].downcase}%",
                                                 "#{words[1].downcase}%",
                                                 "#{words[0].downcase}%").limit(10))
      else
        condition = "lower(firstname) LIKE ? OR lower(lastname) LIKE ?"
        render :json => create_response(Volunteer.select('id, mail, firstname, lastname, birthday, gender, city')
                                          .where(condition,
                                                 "#{words[0].downcase}%",
                                                 "#{words[0].downcase}%").limit(10))
      end
    rescue => e
      render :json => create_error(400, t("volunteers.failure.research"))
    end
  end
  
  api :PUT, '/volunteers/:id', "Update volunteer"
  param_group :volunteers_update
  example SampleJson.volunteers('update')
  def update
    begin
      if !Volunteer.is_new_mail_available?(volunteer_params[:mail], @volunteer.mail)
        render :json => create_error(400, t("volunteers.failure.mail.unavailable"))
      elsif @volunteer.update!(volunteer_params)
        render :json => create_response(@volunteer.simple_description)
      else
        render :json => create_error(400, t("volunteers.failure.update"))
      end
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  api :GET, '/volunteers/:id/notifications', "Get notifications of volunteer"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('notifications')
  def notifications
    render :json => create_response(@volunteer.notifications)
  end

  api :GET, '/volunteers/:id/friends', 'Return a list of the friends of the volunteer referred by id'
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('friends')
  def friends
    render :json => create_response(@volunteer.friends)
  end

  api :GET, '/volunteers/:id/associations', "Return a list of the volunteer's associations"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('associations')
  def associations
    query = "SELECT assocs.id, assocs.name, assocs.city, av_links.rights, " +
      "(SELECT COUNT(*) FROM av_links INNER JOIN v_friends ON " +
      "av_links.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE assoc_id=assocs.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members" +
      " FROM assocs INNER JOIN av_links ON av_links.assoc_id=assocs.id " + 
      "WHERE av_links.volunteer_id=#{@volunteer.id}"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  api :GET, '/volunteers/:id/events', "Return a list of the volunteer's events"
  param :token, String, "Your token", :required => true
  example SampleJson.volunteers('events')
  def events
    query = "SELECT events.id, events.title, events.place, events.begin, " +
      "events.assoc_id, event_volunteers.rights, " +
      "(SELECT COUNT(*) FROM event_volunteers INNER JOIN v_friends ON " +
      "event_volunteers.volunteer_id=v_friends.friend_volunteer_id " +
      "WHERE event_id=events.id AND v_friends.volunteer_id=#{@volunteer.id}) AS nb_friends_members" +
      " FROM events INNER JOIN event_volunteers ON event_volunteers.event_id=events.id " + 
      "WHERE event_volunteers.volunteer_id=#{@volunteer.id}"

    render :json => create_response(ActiveRecord::Base.connection.execute(query))
  end

  private
  def set_volunteer
    begin
      @volunteer = Volunteer.find(params[:id])
    rescue
      render :json => create_error(400, t("volunteers.failure.id"))
      return
    end
  end

  def set_current_volunteer
    @current_volunteer = Volunteer.find_by(token: params[:token])
  end
  
  def volunteer_params
    params.permit(:mail, :password, :firstname, :lastname,
                  :birthday, :gender, :city, :latitude, :longitude,
                  :allowgps)
  end
  
  def generate_token
    SecureRandom.uuid.gsub(/\-/, '')
  end
end
