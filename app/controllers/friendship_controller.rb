class FriendshipController < ApplicationController
  swagger_controller :friendship, "Friendship management"
  
  skip_before_filter :verify_authenticity_token
  before_action :authenticate_volunteer!, unless: :is_swagger_request?

  swagger_api :add do
    summary "Sends a friend request"
    param :query, :token, :string, :required, "Your token"
    param :query, :volunteer_id, :integer, :required, "Volunteer's id to invite"
    response :ok    
  end
  def add
    begin
      @friend = Volunteer.find_by!(id: params[:volunteer_id])
      
      if ((VFriend.where(volunteer_id: current_volunteer.id)
             .where(friend_volunteer_id: @friend.id).first != nil))
        render :json => create_error(400, t("notifications.failure.addfriend.exist")) and return
      elsif ((Notification.where(notif_type: 'AddFriend').where(sender_id: current_volunteer.id)
             .where(receiver_id: @friend.id).first != nil) ||
          (Notification.where(notif_type: 'AddFriend').where(sender_id: @friend.id)
             .where(receiver_id: current_volunteer.id).first != nil))
        render :json => create_error(400, t("notifications.failure.addfriend.pending_invitation"))
        return
      end
      
      if current_volunteer.id == @friend.id
        render :json => create_error(400, t("notifications.failure.addfriend.self"))
        return
      end
      
      @notif = Notification.create!(create_add_friend)

      send_notif_to_socket(@notif)

      render :json => create_response(nil, 200, t("notifications.success.invitefriend"))
    rescue => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  swagger_api :reply do
    summary "Reply to a friend request"
    param :query, :token, :string, :required, "Your token"
    param :query, :notif_id, :integer, :required, "Notification's id"
    param :query, :acceptance, :boolean, :required, "true to accept, false otherwise"
    response :ok
  end
  def reply
    begin
      @notif = Notification.find_by!(id: params[:notif_id])
      
      if current_volunteer.id != @notif.receiver_id
        render :json => create_error(400, t("notifications.failure.rights")) and return
      end

      first_id = @notif.receiver_id
      second_id = @notif.sender_id
      acceptance = params[:acceptance]
      
      if acceptance != nil
        @notif.destroy
      end
      
      if acceptance.eql? 'true'
        create_friend_link(first_id, second_id)
      end
      
      render :json => create_response(nil, 200, t("notifications.success.replyfriend"))
    rescue ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s) and return
    rescue ActiveRecord::RecordNotFound => e
      render :json => create_error(404, e.to_s) and return      
    end
  end

  swagger_api :remove do
    summary "Remove friendship"
    param :query, :token, :string, :required, "Your token"
    param :query, :volunteer_id, :integer, :required, "Volunteer's id to remove from friends"
    response :ok
  end
  def remove
    begin
      @friend = Volunteer.find_by!(id: params[:id])

      link1 = VFriend.where(volunteer_id: current_volunteer.id)
        .where(friend_volunteer_id: @friend.id).first 
      link2 = VFriend.where(volunteer_id: @friend.id)
        .where(friend_volunteer_id: current_volunteer.id).first 
      if link1 == nil || link2 == nil
        render :json => create_error(400, t("volunteers.failure.unfriend"))
        return
      end
      link1.destroy
      link2.destroy
      render :json => create_response(nil, 200, t("volunteers.success.unfriend"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  swagger_api :received_invitations do
    summary "List all pending friends' invitations"
    param :query, :token, :string, :required, "Your token"
    response :ok
  end
  def received_invitations
    volunteers = Volunteer
                 .select(:id, :firstname, :lastname, :city, :thumb_path)
                 .joins("INNER JOIN notifications ON notifications.sender_id=volunteers.id")
                 .select("notifications.id AS notif_id")
                 .where("notifications.receiver_id=#{current_volunteer.id}")
    render :json => create_response(volunteers)
  end
  
  private
  def create_add_friend
    {sender_id: current_volunteer.id,
     sender_name: current_volunteer.fullname,
     thumb_path: current_volunteer.thumb_path,
     receiver_id: @friend.id,
     receiver_name: @friend.fullname,
     notif_type: 'AddFriend'}
  end

  def create_friend_link(sender, receiver)
    begin
      VFriend.create!([volunteer_id: sender, friend_volunteer_id: receiver])
      VFriend.create!([volunteer_id: receiver, friend_volunteer_id: sender])
      return true
    rescue ActiveRecord::RecordInvalid => e
      return false
    end
  end  
end
