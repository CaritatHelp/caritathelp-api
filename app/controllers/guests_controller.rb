class GuestsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :check_token
  before_action :set_event, except: [:reply_invite, :reply_guest]
  before_action :set_volunteer
  before_action :check_rights, only: [:kick, :upgrade]

  api :DELETE, '/guests/kick', "Kick guest from the event"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of guest to kick", :required => true
  param :event_id, String, "Event concerned", :required => true
  example SampleJson.guests('kick')
  def kick
    begin
      @to_kick = Volunteer.find_by!(id: params[:volunteer_id])

      volunteer_link = EventVolunteer.where(event_id: @event.id)
        .where(volunteer_id: @volunteer.id).first
      if (volunteer_link == nil)
        render :json => create_error(400, t("events.failure.rights")) and return
      end

      to_kick_link = EventVolunteer.where(event_id: @event.id).where(volunteer_id: @to_kick.id).first
      if (to_kick_link == nil)
        render :json => create_error(400, t("events.failure.not_guest")) and return
      end

      if volunteer_link.level <= to_kick_link.level
        render :json => create_error(400, t("events.failure.rights")) and return
      end

      to_kick_link.destroy
      render :json => create_response(nil, 200, t("events.success.kicked"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :PUT, '/guests/upgrade', "Change rights of guest"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of guest to upgrade", :required => true
  param :event_id, String, "Event concerned", :required => true
  param :rights, String, "New rights to apply", :required => true
  example SampleJson.guests('upgrade')
  def upgrade
    begin
      @to_up = Volunteer.find_by!(id: params[:volunteer_id])
      
      volunteer_link = EventVolunteer.where(event_id: @event.id)
        .where(volunteer_id: @volunteer.id).first
      if (volunteer_link == nil)
        render :json => create_error(400, t("events.failure.rights")) and return
      end
      
      to_up_link = EventVolunteer.where(event_id: @event.id).where(volunteer_id: @to_up.id).first
      if (to_up_link == nil)
        render :json => create_error(400, t("events.failure.not_guest")) and return
      end

      if volunteer_link.level <= to_up_link.level
        render :json => create_error(400, t("events.failure.rights")) and return        
      end

      # il se passe quoi si je mets des wrong rights?

      to_up_link.update!({:rights => params[:rights]})
      render :json => create_response(nil, 200, t("events.success.upgraded"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :POST, '/guests/join', "Ask to join an event"
  param :token, String, "Your token", :required => true
  param :event_id, String, "Event concerned", :required => true
  example SampleJson.guests('join')
  def join
    begin
      # Check if already guest or if already applied
      if ((EventVolunteer.where(volunteer_id: @volunteer.id)
             .where(event_id: @event.id).first != nil) ||
          (Notification.where(notif_type: 'JoinEvent')
             .where(sender_id: @volunteer.id)
             .where(event_id: @event.id).first != nil) ||
          (Notification.where(notif_type: 'InviteGuest')
             .where(event_id: @event.id)
             .where(receiver_id: @volunteer.id).first != nil))
        render :json => create_error(400, t("events.failure.join_link_exist"))
        return
      end
      
      # create a notification for the event receiving the request
      notif = Notification.create!(create_join_event)

      # create a link between the notification and each admin of the event
      Volunteer.joins(:event_volunteers)
        .where(event_volunteers: { event_id: @event.id })
        .where("event_volunteers.level > ?", 1)
        .select("volunteers.id").all.each do |volunteer|
        NotificationVolunteer.create!([
                                       volunteer_id: volunteer['id'],
                                       notification_id: notif[0].id,
                                       read: false
                                      ])
      end

      send_notif_to_socket(notif[0])
      
      render :json => create_response(nil, 200, t("events.success.join_event"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :POST, '/guests/reply_guest', "Respond to a guest request to join the event"
  param :token, String, "Your token", :required => true
  param :notif_id, String, "Notification's id", :required => true
  param :acceptance, String, "True to accept, false otherwise", :required => true
  example SampleJson.guests('reply_guest')
  def reply_guest
    begin
      @notif = Notification.find_by!(id: params[:notif_id])
      
      # Check the rights of the person who's trying to accept a guest
      link = EventVolunteer.where(volunteer_id: @volunteer.id)
        .where(event_id: @notif.event_id).first
      if ((link.eql? nil) || (link.rights.eql? 'member'))
        render :json => create_error(400, t("events.failure.rights")) and return
      end
      
      guest_id = @notif.sender_id
      event_id = @notif.event_id
      acceptance = params[:acceptance]
 
      # modify the notification if there is a clear answer
      if acceptance != nil
        @notif.notif_type = 'NewGuest'
        @notif.save!
        send_notif_to_socket(@notif)
      end
      
      if acceptance.eql? 'true'
        create_guest_link(guest_id, event_id)
      end
      
      render :json => create_response(nil, 200, t("events.success.reply_guest"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end
  
  api :POST, '/guests/invite', "Invite a volunteer to join the event"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of the volunteer to invite", :required => true
  param :event_id, String, "Id of the event", :required => true
  example SampleJson.guests('invite')
  def invite
    begin
      @invited_vol = Volunteer.find_by!(id: params[:volunteer_id])
      
      # Check if volunteer has the permission to invite a guest in event
      link = EventVolunteer.where(volunteer_id: @volunteer.id).where(event_id: @event.id).first
      if ((link.eql? nil) || (link.rights.eql? 'member'))
        render :json => create_error(400, t("events.failure.rights")) and return
      end      
      
      # Check if invited_vol is already guest or if already applied
      if ((EventVolunteer.where(volunteer_id: @invited_vol.id)
             .where(event_id: @event.id).first != nil) ||
          (Notification.where(notif_type: 'JoinEvent')
             .where(sender_id: @invited_vol.id)
             .where(event_id: @event.id).first != nil) ||
          (Notification.where(notif_type: 'InviteGuest')
             .where(event_id: @event.id)
             .where(receiver_id: @invited_vol.id).first != nil))
        render :json => create_error(400, t("events.failure.invite_link_exist")) and return
      end
      
      # create a notification for volunteer receiving invitation
      notif = Notification.create!(create_invite_guest)

      send_notif_to_socket(notif[0])
      
      render :json => create_response(nil, 200, t("events.success.invite_guest"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :POST, '/guests/reply_invite', "Respond to an invitation from an event"
  param :token, String, "Your token", :required => true
  param :notif_id, String, "Notification's id", :required => true
  param :acceptance, String, "True to accept, false otherwise", :required => true
  example SampleJson.guests('reply_invite')
  def reply_invite
    begin
      @notif = Notification.find_by!(id: params[:notif_id])
      
      # Check the right of the person who's trying to accept invitation
      if @volunteer.id != @notif.receiver_id
        render :json => create_error(400, t("events.failure.rights")) and return        
      end
      
      guest_id = @notif.receiver_id
      event_id = @notif.event_id
      acceptance = params[:acceptance]
      
      # destroy the notification if there is a clear answer
      if acceptance != nil
        @notif.destroy
      end
      
      # create guest link if the invited volunteer accept invitation
      if acceptance.eql? 'true'
        create_guest_link(guest_id, event_id)
      end

      render :json => create_response(nil, 200, t("events.success.reply_invite"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :DELETE, '/guests/leave', "Leave an event"
  param :token, String, "Your token", :required => true
  param :event_id, String, "Id of the event to leave", :required => true
  example SampleJson.guests('leave')
  def leave_event
    begin
      volunteer = Volunteer.find_by!(token: params[:token])
      event = Event.find_by!(id: params[:event_id])

      link = EventVolunteer.where(:volunteer_id => volunteer.id).where(:event_id => event.id).first

      if link.eql?(nil)
        render :json => create_error(400, t("events.failure.not_guest")) and return        
      elsif link.rights.eql?('host')
        render :json => create_error(400, t("events.failure.host")) and return
      end

      link.destroy

      render :json => create_response(t("events.success.leaved")) and return
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  private
  def join_params
    params.permit(:token)
  end

  def set_event
    begin
      @event = Event.find(params[:event_id])
    rescue
      render :json => create_error(400, t("events.failure.id")), status: 400
    end
  end

  def set_volunteer
    begin
      @volunteer = Volunteer.find_by(token: params[:token])
    rescue
      render :json => create_error(400, t("volunteers.failure.id")), status: 400
    end
  end

  def create_join_event
    [sender_id: @volunteer.id,
     sender_name: @volunteer.firstname + " " + @volunteer.lastname,
     event_id: @event.id,
     event_name: @event.title,
     notif_type: 'JoinEvent']
  end

  def create_invite_guest
    [event_id: @event.id,
     event_name: @event.title,
     sender_id: @volunteer.id,
     sender_name: @volunteer.firstname + " " + @volunteer.lastname,
     receiver_id: @invited_vol.id,
     receiver_name: @invited_vol.firstname + " " + @invited_vol.lastname,
     notif_type: 'InviteGuest']
  end

  def create_guest_link(guest_id, event_id)
    begin
      EventVolunteer.create!([event_id: event_id, volunteer_id: guest_id, rights: 'member'])
      return true
    rescue ActiveRecord::RecordInvalid => e
      return false
    end
  end

  def check_rights
    @link = EventVolunteer.where(:volunteer_id => @volunteer.id)
      .where(:event_id => @event.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("events.failure.rights"))
      return false
    end
    return true
  end
end
