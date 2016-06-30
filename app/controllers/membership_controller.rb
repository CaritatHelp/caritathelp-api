class MembershipController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :check_token
  before_action :set_volunteer
  before_action :set_assoc, except: [:reply_member, :reply_invite]
  before_action :check_rights, except: [:join_assoc, :reply_invite, :leave_assoc]

  api :DELETE, '/membership/kick', "Kick member from the association"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of member to kick", :required => true
  param :assoc_id, String, "Association concerned", :required => true
  example SampleJson.membership('kick')
  def kick
    begin
      @to_kick = Volunteer.find_by!(id: params[:volunteer_id])

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
      # Check if already member or if already applied
      if ((AvLink.where(volunteer_id: @volunteer.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification.where(notif_type: 'JoinAssoc')
             .where(sender_id: @volunteer.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification.where(notif_type: 'InviteMember')
             .where(assoc_id: @assoc.id)
             .where(receiver_id: @volunteer.id).first != nil))
        render :json => create_error(400, t("notifications.failure.joinassoc.exist"))
        return
      end
      
      # create a notification for the association receiving the request
      notif = Notification.create!(create_join_assoc)

      Volunteer.joins(:av_links)
        .where(av_links: { assoc_id: @assoc.id })
        .where("av_links.level > ?", 1)
        .select("volunteers.id").all.each do |volunteer|
        NotificationVolunteer.create!([
                                       volunteer_id: volunteer['id'],
                                       notification_id: notif[0].id,
                                       read: false
                                      ])
      end

      send_notif_to_socket(notif[0])
      
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
      @notif = Notification.find_by!(id: params[:notif_id])
            
      member_id = @notif.sender_id
      assoc_id = @notif.assoc_id
      acceptance = params[:acceptance]
 
      # destroy the notification if there is a clear answer
      if acceptance != nil
        @notif.notif_type = 'NewMember'
        @notif.save!
        send_notif_to_socket(@notif)
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
            
      # Check if invited_member is already member or if already applied
      if ((AvLink.where(volunteer_id: @invited_vol.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification.where(notif_type: 'JoinAssoc')
             .where(sender_id: @invited_vol.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification.where(notif_type: 'InviteMember')
             .where(assoc_id: @assoc.id)
             .where(receiver_id: @invited_vol.id).first != nil))
        render :json => create_error(400, t("notifications.failure.invitemember.exist")) and return
      end
      
      # create a notification for volunteer receiving invitation
      notif = Notification.create!(create_invite_member)
      
      send_notif_to_socket(notif[0])

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
      @notif = Notification.find_by!(id: params[:notif_id])
      
      # Check the right of the person who's trying to accept invitation
      if @volunteer.id != @notif.receiver_id
        render :json => create_error(400, t("notifications.failure.rights")) and return        
      end
      
      member_id = @notif.receiver_id
      assoc_id = @notif.assoc_id
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
      link = AvLink.where(:volunteer_id => @volunteer.id).where(:assoc_id => @assoc.id).first

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

  api :GET, 'membership/invited', "List all invited volunteers"
  param :token, String, "Your token", :required => true
  param :assoc_id, String, "Id of the association", :required => true
  example SampleJson.membership('invited')
  def invited
    invited_volunteers = Volunteer.joins("INNER JOIN notifications ON notifications.receiver_id=volunteers.id")
      .where("notifications.notif_type='InviteMember'")
      .where("notifications.assoc_id=#{@assoc.id}")
      .select("volunteers.*, notifications.created_at AS sending_date")
    render :json => create_response(invited_volunteers
                                      .as_json(except: [:token, :password,
                                                       :created_at, :updated_at]))
  end

  api :DELETE, 'membership/uninvite', "Remove invitation to volunteer"
  param :token, String, "Your token", :required => true
  param :assoc_id, String, "Id of the association", :required => true
  param :volunteer_id, String, "Id of the volunteer to uninvite", :required => true
  example SampleJson.membership('uninvite')
  def uninvite
    begin
      @to_uninvite = Volunteer.find_by!(id: params[:volunteer_id])
      
      notif = Notification.where(notif_type: "InviteMember")
        .where(assoc_id: @assoc.id)
        .where(receiver_id: @to_uninvite.id).first
      
      if notif.blank?
        render :json => create_error(400, t("assocs.failure.uninvite")) and return
      end

      notif.destroy 
      
      render :json => create_response(t("assocs.success.uninvited"))
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  api :GET, 'membership/waiting', "List all volunteers waiting to join the assoc"
  param :token, String, "Your token", :required => true
  param :assoc_id, String, "Id of the association", :required => true
  example SampleJson.membership('waiting')
  def waiting
    waiting_volunteers = Volunteer.joins("INNER JOIN notifications ON notifications.sender_id=volunteers.id")
      .where("notifications.notif_type='JoinAssoc'")
      .where("notifications.assoc_id=#{@assoc.id}")
      .select("volunteers.*, notifications.created_at AS sending_date")
    render :json => create_response(waiting_volunteers
                                      .as_json(except: [:token, :password,
                                                        :created_at, :updated_at]))
  end

  private
  def join_params
    params.permit(:token)
  end

  def create_join_assoc
    [sender_id: @volunteer.id,
     sender_name: @volunteer.fullname,
     thumb_path: @volunteer.thumb_path,
     assoc_id: @assoc.id,
     assoc_name: @assoc.name,
     notif_type: 'JoinAssoc']
  end

  def create_invite_member
    [assoc_id: @assoc.id,
     assoc_name: @assoc.name,
     thumb_path: @assoc.thumb_path,
     sender_id: @volunteer.id,
     sender_name: @volunteer.fullname,
     receiver_id: @invited_vol.id,
     receiver_name: @invited_vol.fullname,
     notif_type: 'InviteMember']
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

  def set_assoc
    begin
      @assoc = Assoc.find_by!(id: params[:assoc_id])
    rescue
      render :json => create_error(400, t("assocs.failure.id")) and return
    end
  end

  def check_rights
    @link = AvLink.where(:volunteer_id => @volunteer.id)
      .where(:assoc_id => @assoc.id).first
    if @link.eql?(nil) || @link.rights.eql?('member')
      render :json => create_error(400, t("assocs.failure.rights"))
      return false
    end
    return true
  end

end
