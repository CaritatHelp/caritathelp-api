class MembershipController < ApplicationController
  swagger_controller :members, "Members management"

  skip_before_filter :verify_authenticity_token

  before_action :authenticate_volunteer!, unless: :is_swagger_request?

  before_action :set_target_volunteer, only: [:kick, :upgrade, :invite, :uninvite]
  before_action :set_assoc, except: [:reply_member, :reply_invite]
  before_action :check_target_follower, only: [:kick, :upgrade]
  before_action :check_rights, except: [:join_assoc, :reply_invite, :reply_member, :leave_assoc, :unjoin]

  swagger_api :kick do
    summary "Kick member"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :volunteer_id, :integer, :required, "Volunteer's id to kick"
    param :query, :assoc_id, :integer, :required, "Association's id"
    response :ok
  end
  def kick
    begin
      volunteer_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: current_volunteer.id).first
      if (volunteer_link == nil)
        render :json => create_error(400, t("assocs.failure.rights")) and return
      end

      to_kick_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @target_volunteer.id).first
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

  swagger_api :upgrade do
    summary "Upgrade member"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :volunteer_id, :integer, :required, "Volunteer's id to upgrade"
    param :query, :assoc_id, :integer, :required, "Association's id"
    param :query, :rights, :string, :required, "Rights to apply"
    response :ok
  end
  def upgrade
    begin
      volunteer_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: current_volunteer.id).first
      if (volunteer_link == nil)
        render :json => create_error(400, t("assocs.failure.rights")) and return
      end

      to_up_link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @target_volunteer.id).first
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

  swagger_api :join_assoc do
    summary "Request to join an association"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id"
    response :ok
  end
  def join_assoc
    begin
      # Check if already member or if already applied
      link = AvLink.where(volunteer_id: current_volunteer.id).where(assoc_id: @assoc.id).first
      if ((link != nil and !link.level.eql?(AvLink.levels['follower'])) ||
          (Notification.where(notif_type: 'JoinAssoc')
             .where(sender_id: current_volunteer.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification.where(notif_type: 'InviteMember')
             .where(assoc_id: @assoc.id)
             .where(receiver_id: current_volunteer.id).first != nil))
        render :json => create_error(400, t("notifications.failure.joinassoc.exist"))
        return
      end

      # create a notification for the association receiving the request
      notif = Notification.create!(create_join_assoc)

      Volunteer.joins(:av_links)
        .where(av_links: { assoc_id: @assoc.id })
        .where("av_links.level > ?", 5)
        .select("volunteers.id").all.each do |volunteer|
        NotificationVolunteer.create!([
                                       volunteer_id: volunteer['id'],
                                       notification_id: notif[0].id,
                                       read: false
                                      ])
      end

      #send_notif_to_socket(notif[0]) unless Rails.env.test?

      render :json => create_response(nil, 200, t("notifications.success.joinassoc"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :reply_member do
    summary "Respond to a request to join the association"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :notif_id, :integer, :required, "Notification's id"
    param :query, :acceptance, :boolean, :required, "true to accept, false otherwise"
    response :ok
  end
  def reply_member
    begin
      @notif = Notification.find_by!(id: params[:notif_id])

      # Check the rights of the person who's trying to accept a member
      link = AvLink.where(volunteer_id: current_volunteer.id)
             .where(assoc_id: @notif.assoc_id).first
      if ((link.eql? nil) || (link.rights.eql? 'member'))
        render :json => create_error(400, t("assocs.failure.rights")) and return
      end

      member_id = @notif.sender_id
      assoc_id = @notif.assoc_id
      acceptance = params[:acceptance]

      if acceptance == true or acceptance == "true"
        @notif.notif_type = 'NewMember'
        @notif.save!
        send_notif_to_socket(@notif) unless Rails.env.test?
        create_member_link(member_id, assoc_id)
        render :json => create_response(t("notifications.success.addmember"))
      else
        @notif.destroy
        render :json => create_response(t("notifications.success.refused_member"))
      end

    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :invite do
    summary "Invite a volunteer to join the association"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :volunteer_id, :integer, :required, "Volunteer's id to invite"
    param :query, :assoc_id, :integer, :required, "Association's id"
    response :ok
  end
  def invite
    begin
      # Check if invited_member is already member or if already applied
      if ((AvLink.where(volunteer_id: @target_volunteer.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification.where(notif_type: 'JoinAssoc')
             .where(sender_id: @target_volunteer.id)
             .where(assoc_id: @assoc.id).first != nil) ||
          (Notification.where(notif_type: 'InviteMember')
             .where(assoc_id: @assoc.id)
             .where(receiver_id: @target_volunteer.id).first != nil))
        render :json => create_error(400, t("notifications.failure.invitemember.exist")) and return
      end

      # create a notification for volunteer receiving invitation
      notif = Notification.create!(create_invite_member)

      send_notif_to_socket(notif[0]) unless Rails.env.test?

      render :json => create_response(nil, 200, t("notifications.success.invitemember"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :reply_invite do
    summary "Respond to an invitation"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :notif_id, :integer, :required, "Notification's id"
    param :query, :acceptance, :boolean, :required, "true to accept, false otherwise"
    response :ok
  end
  def reply_invite
    begin
      @notif = Notification.find_by!(id: params[:notif_id])

      # Check the right of the person who's trying to accept invitation
      if current_volunteer.id != @notif.receiver_id
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
      if acceptance == true or acceptance == "true"
        create_member_link(member_id, assoc_id)
      end

      render :json => create_response(nil, 200, t("notifications.success.acceptinvite"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    end
  end

  swagger_api :leave_assoc do
    summary "Leave an association"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id to leave"
    response :ok
  end
  def leave_assoc
    begin
      link = AvLink.where(:volunteer_id => current_volunteer.id).where(:assoc_id => @assoc.id).first

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

  swagger_api :invited do
    summary "List all invited volunteers"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id"
    response :ok
  end
  def invited
    target_volunteerunteers = Volunteer.joins("INNER JOIN notifications ON notifications.receiver_id=volunteers.id")
      .where("notifications.notif_type='InviteMember'")
      .where("notifications.assoc_id=#{@assoc.id}")
      .select("volunteers.*, notifications.created_at AS sending_date")
    render :json => create_response(target_volunteerunteers
                                     .as_json(except: [:password,
                                                       :created_at, :updated_at]))
  end

  swagger_api :uninvite do
    summary "Cancel an invitation"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id"
    param :query, :volunteer_id, :integer, :required, "Volunteer's id"
    response :ok
  end
  def uninvite
    begin
      notif = Notification.where(notif_type: "InviteMember")
        .where(assoc_id: @assoc.id)
        .where(receiver_id: @target_volunteer.id).first

      if notif.blank?
        render :json => create_error(400, t("assocs.failure.uninvite")) and return
      end

      notif.destroy

      render :json => create_response(t("assocs.success.uninvited"))
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  swagger_api :unjoin do
    summary "Cancel a joining request"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id"
    response :ok
  end
  def unjoin
    begin
      notif = current_volunteer.notifications.select(&:is_join_assoc?).select { |notification| notification.assoc_id == @assoc.id }.first

      if notif.blank?
        render json: create_error(400, t("assocs.failure.unjoin")) and return
      end

      notif.destroy

      render json: create_response(t("assocs.success.unjoin"))
    rescue => e
      render :json => create_error(400, e.to_s)
    end
  end

  swagger_api :waiting do
    summary "List all volunteers waiting to join the association"
    param :header, 'access-token', :string, :required, "Access token"
    param :header, :client, :string, :required, "Client token"
    param :header, :uid, :string, :required, "Volunteer's uid (email address)"
    param :query, :assoc_id, :integer, :required, "Association's id"
  end
  def waiting
    waiting_volunteers = Volunteer.joins("INNER JOIN notifications ON notifications.sender_id=volunteers.id")
      .where("notifications.notif_type='JoinAssoc'")
      .where("notifications.assoc_id=#{@assoc.id}")
      .select("volunteers.*, notifications.created_at AS sending_date, notifications.id AS notif_id")
    render :json => create_response(waiting_volunteers
                                     .as_json(except: [:password,
                                                       :created_at, :updated_at]))
  end

  private
  def create_join_assoc
    [sender_id: current_volunteer.id,
     assoc_id: @assoc.id,
     notif_type: 'JoinAssoc']
  end

  def create_invite_member
    [assoc_id: @assoc.id,
     sender_id: current_volunteer.id,
     receiver_id: @target_volunteer.id,
     notif_type: 'InviteMember']
  end

  def create_member_link(member_id, assoc_id)
    begin
      link = AvLink.where(assoc_id: assoc_id).where(volunteer_id: member_id).first

      if link.eql?(nil)
        AvLink.create!([assoc_id: assoc_id, volunteer_id: member_id, rights: 'member'])
      elsif link.rights.eql?('follower')
        link.rights = 'member'
        link.save!
      elsif link.rights.eql?('block')
        render :json => create_error(400, t("assocs.failure.blocked")) and return
      end
      return true
    rescue ActiveRecord::RecordInvalid => e
      return false
    end
  end

  def set_target_volunteer
    begin
      @target_volunteer = Volunteer.find_by!(id: params[:volunteer_id])
    rescue
      render :json => create_error(400, t("volunteers.failure.id")) and return
    end
  end

  def set_assoc
    begin
      @assoc = Assoc.find_by!(id: params[:assoc_id])
    rescue
      render :json => create_error(400, t("assocs.failure.id")) and return
    end
  end

  def check_target_follower
    link = AvLink.where(assoc_id: @assoc.id).where(volunteer_id: @target_volunteer.id).first
    if link.eql?(nil) or link.rights.eql?('follower')
      render :json => create_error(400, t("assocs.failure.follower"))
    end
  end

  def check_rights
    @link = AvLink.where(:volunteer_id => current_volunteer.id)
      .where(:assoc_id => @assoc.id).first
    if @link.eql?(nil) || @link.rights.eql?('member') || @link.rights.eql?('follower')
      render :json => create_error(400, t("assocs.failure.rights"))
      return false
    end
    return true
  end

end
