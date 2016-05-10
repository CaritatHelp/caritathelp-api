class MembershipController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :check_token
  before_action :set_volunteer
  before_action :check_rights, only: [:kick, :upgrade]

  api :DELETE, '/membership/kick', "Kick member from the association"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of member to kick", :required => true
  param :assoc_id, String, "Association concerned", :required => true
  example SampleJson.membership('kick')
  def kick
    begin
      @to_kick = Volunteer.find_by!(id: params[:volunteer_id])
      @assoc = Assoc.find_by!(id: params[:assoc_id])

      volunteer_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @volunteer.id).first
      if (volunteer_link == nil)
        render :json => create_error(400, t("assocs.failure.rights")) and return
      end

      to_kick_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @to_kick.id).first
      if (to_kick_link == nil)
        render :json => create_error(400, t("assocs.failure.notmember")) and return
      end

      if volunteer_link.level <= to_kick_link.level
        render :json => create_error(400, t("assocs.failure.rights")) and return
      end

      to_kick_link.destroy
      render :json => create_response(nil, 200, t("assocs.success.kicked"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :PUT, '/membership/upgrade', "Change rights of member"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of member to upgrade", :required => true
  param :assoc_id, String, "Association concerned", :required => true
  param :rights, String, "New rights to apply", :required => true
  example SampleJson.membership('upgrade')
  def upgrade
    begin
      @to_up = Volunteer.find_by!(id: params[:volunteer_id])
      @assoc = Assoc.find_by!(id: params[:assoc_id])
      
      volunteer_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @volunteer.id).first
      if (volunteer_link == nil)
        render :json => create_error(400, t("assocs.failure.rights")) and return
      end
      
      to_up_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @to_up.id).first
      if (to_up_link == nil)
        render :json => create_error(400, t("assocs.failure.notmember")) and return
      end

      if volunteer_link.level <= to_up_link.level
        render :json => create_error(400, t("assocs.failure.rights")) and return        
      end

      to_up_link.update!({:rights => params[:rights]})
      render :json => create_response(nil, 200, t("assocs.success.upgraded"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :POST, '/membership/join', "Ask to join an association"
  param :token, String, "Your token", :required => true
  param :assoc_id, String, "Association concerned", :required => true
  example SampleJson.membership('join')
  def join_assoc
    begin
      @assoc = Assoc.find_by!(id: params[:assoc_id])
      
      # Check if already member or if already applied
      if ((AvLink.where(volunteer_id: @volunteer.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification::JoinAssoc.where(sender_volunteer_id: @volunteer.id)
             .where(receiver_assoc_id: @assoc.id).first != nil) ||
          (Notification::InviteMember.where(sender_assoc_id: @assoc.id)
             .where(receiver_volunteer_id: @volunteer.id).first != nil))
        render :json => create_error(400, t("notifications.failure.joinassoc.exist"))
        return
      end
      
      # create a notification for the association receiving the request
      notif = Notification::JoinAssoc.create!(create_join_assoc)
      
      render :json => create_response(nil, 200, t("notifications.success.joinassoc"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :POST, '/membership/reply_member', "Respond to a member request to join the association"
  param :token, String, "Your token", :required => true
  param :notif_id, String, "Notification's id", :required => true
  param :acceptance, String, "True to accept, false otherwise", :required => true
  example SampleJson.membership('reply_member')
  def reply_member
    begin
      @notif = Notification::JoinAssoc.find_by!(id: params[:notif_id])
      
      # Check the rights of the person who's trying to accept a member
      tmp = AvLink.where(volunteer_id: @volunteer.id).where(assoc_id: @notif.receiver_assoc_id).first
      if ((tmp.eql? nil) || (tmp.rights.eql? 'member'))
        render :json => create_error(400, t("notifications.failure.rights")) and return
      end
      
      member_id = @notif.sender_volunteer_id
      assoc_id = @notif.receiver_assoc_id
      acceptance = params[:acceptance]
 
      # destroy the notification if there is a clear answer
      if acceptance != nil
        @notif.destroy
      end
      
      if acceptance.eql? 'true'
        create_member_link(member_id, assoc_id)
      end
      
      render :json => create_response(nil, 200, t("notifications.success.addmember"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end
  
  api :POST, '/membership/invite', "Invite a volunteer to join the assocation"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of the volunteer to invite", :required => true
  param :assoc_id, String, "Id of the association", :required => true
  example SampleJson.membership('invite')
  def invite
    begin
      @invited_vol = Volunteer.find_by!(id: params[:volunteer_id])
      @assoc = Assoc.find_by!(id: params[:assoc_id])
      
      # Check if @volunteer has the permission to invite a member in assoc
      tmp = AvLink.where(volunteer_id: @volunteer.id).where(assoc_id: @assoc.id).first
      if ((tmp.eql? nil) || (tmp.rights.eql? 'member'))
        render :json => create_error(400, t("notifications.failure.rights")) and return
      end      
      
      # Check if invited_member is already member or if already applied
      if ((AvLink.where(volunteer_id: @invited_vol.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification::JoinAssoc.where(sender_volunteer_id: @invited_vol.id)
             .where(receiver_assoc_id: @assoc.id).first != nil) ||
          (Notification::InviteMember.where(sender_assoc_id: @assoc.id)
             .where(receiver_volunteer_id: @invited_vol.id).first != nil))
        render :json => create_error(400, t("notifications.failure.invitemember.exist")) and return
      end
      
      # create a notification for volunteer receiving invitation
      notif = Notification::InviteMember.create!(create_invite_member)
      
      render :json => create_response(nil, 200, t("notifications.success.invitemember"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :POST, '/membership/reply_invite', "Respond to an invitation form an association"
  param :token, String, "Your token", :required => true
  param :notif_id, String, "Notification's id", :required => true
  param :acceptance, String, "True to accept, false otherwise", :required => true
  example SampleJson.membership('reply_invite')
  def reply_invite
    begin
      @notif = Notification::InviteMember.find_by!(id: params[:notif_id])
      
      # Check the right of the person who's trying to accept invitation
      if @volunteer.id != @notif.receiver_volunteer_id
        render :json => create_error(400, t("notifications.failure.rights")) and return        
      end
      
      member_id = @notif.receiver_volunteer_id
      assoc_id = @notif.sender_assoc_id
      acceptance = params[:acceptance]
      
      # destroy the notification if there is a clear answer
      if acceptance != nil
        @notif.destroy
      end
      
      # create member link if the invited volunteer accept invitation
      if acceptance.eql? 'true'
        create_member_link(member_id, assoc_id)
      end

      render :json => create_response(nil, 200, t("notifications.success.acceptinvite"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  api :DELETE, '/membership/leave', "Leave an association"
  param :token, String, "Your token", :required => true
  param :assoc_id, String, "Id of the assoc to leave", :required => true
  example SampleJson.membership('leave')
  def leave_assoc
    begin
      assoc = Assoc.find_by!(id: params[:assoc_id])

      link = AvLink.where(:volunteer_id => @volunteer.id).where(:assoc_id => assoc.id).first

      if link.eql?(nil)
        render :json => create_error(400, t("assocs.failure.notmember")) and return        
      elsif link.rights.eql?('owner')
        render :json => create_error(400, t("assocs.failure.owner")) and return
      end

      link.destroy

      render :json => create_response(t("assocs.success.leaved")) and return
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  private
  def join_params
    params.permit(:token)
  end

  def create_join_assoc
    [sender_volunteer_id: @volunteer.id,
     receiver_assoc_id: @assoc.id]
  end

  def create_invite_member
    [sender_assoc_id: @assoc.id,
     receiver_volunteer_id: @invited_vol.id]
  end

  def create_member_link(member_id, assoc_id)
    begin
      AvLink.create!([assoc_id: assoc_id, volunteer_id: member_id, rights: 'member'])
      return true
    rescue ActiveRecord::RecordInvalid => e
      return false
    end
  end

  def set_volunteer
    @volunteer = Volunteer.find_by!(token: params[:token])
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
