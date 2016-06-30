class FriendshipController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :check_token
    
  def_param_group :respond_friend do
    param :token, String, "Volunteer token", :required => true
    param :notif_id, String, "Id of the notification", :required => true
    param :acceptance, String, "True if friendship accepted, false otherwise", :required => true
  end
  
  api :POST, '/friendship/add', "Send a friend request to 'id' volunteer"
  param :token, String, "Your token", :required => true
  param :volunteer_id, String, "Id of volunteer to add as friend", :required => true
  example SampleJson.friendship('add')
  def add
    begin
      @volunteer = Volunteer.find_by!(token: params[:token])
      @friend = Volunteer.find_by!(id: params[:volunteer_id])
      
      if ((VFriend.where(volunteer_id: @volunteer.id)
             .where(friend_volunteer_id: @friend.id).first != nil) ||
          (Notification.where(notif_type: 'AddFriend').where(sender_id: @volunteer.id)
             .where(receiver_id: @friend.id).first != nil) ||
          (Notification.where(notif_type: 'AddFriend').where(sender_id: @friend.id)
             .where(receiver_id: @volunteer.id).first != nil))
        render :json => create_error(400, t("notifications.failure.addfriend.error"))
        return
      end
      
      if @volunteer.id == @friend.id
        render :json => create_error(400, t("notifications.failure.addfriend.self"))
        return
      end
      
      notif = Notification.create!(create_add_friend)

      send_notif_to_socket(notif[0])

      render :json => create_response(nil, 200, t("notifications.success.invitefriend"))
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      render :json => create_error(400, e.to_s)
      return
    end
  end

  api :POST, '/friendship/reply', "Reply to friend request"
  param_group :respond_friend
  example SampleJson.friendship('reply')
  def reply
    begin
      @volunteer = Volunteer.find_by!(token: params[:token])
      @notif = Notification.find_by!(id: params[:notif_id])
      
      if @volunteer.id != @notif.receiver_id
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

  api :DELETE, '/friendship/remove', 'Remove frienship with volunteer referred by id'
  param :token, String, "Your token", :required => true
  param :id, String, "Id of volunteer to unfriend", :required => true
  example SampleJson.friendship('remove')
  def remove
    begin
      @volunteer = Volunteer.find_by!(token: params[:token])
      @friend = Volunteer.find_by!(id: params[:id])

      link1 = VFriend.where(volunteer_id: @volunteer.id)
        .where(friend_volunteer_id: @friend.id).first 
      link2 = VFriend.where(volunteer_id: @friend.id)
        .where(friend_volunteer_id: @volunteer.id).first 
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

  private
  def create_add_friend
    [sender_id: @volunteer.id,
     sender_name: @volunteer.fullname,
     thumb_path: @volunteer.thumb_path,
     receiver_id: @friend.id,
     receiver_name: @friend.fullname,
     notif_type: 'AddFriend']
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
