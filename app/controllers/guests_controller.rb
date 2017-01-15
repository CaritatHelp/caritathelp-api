class GuestsController < ApplicationController
	swagger_controller :guests, "Guests management"

	skip_before_filter :verify_authenticity_token

	before_action :authenticate_volunteer!, unless: :is_swagger_request?

	before_action :set_event
	before_action :set_link, except: [:reply_invite, :leave_event]
	before_action :check_rights, except: [:join, :reply_invite, :leave_event, :unjoin]
	before_action :set_target_volunteer, only: [:kick, :upgrade, :invite, :uninvite]

	swagger_api :kick do
		summary "Kick guest from the event"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :volunteer_id, :integer, :required, "Volunteer's id to kick"
		param :query, :event_id, :integer, :required, "Event's id"
		response :ok
	end
	def kick
		begin
			if (@link == nil)
				render :json => create_error(400, t("events.failure.rights")) and return
			end

			to_kick_link = EventVolunteer.where(event_id: @event.id)
				.where(volunteer_id: @target_volunteer.id).first
			if (to_kick_link == nil)
				render :json => create_error(400, t("events.failure.not_guest")) and return
			end

			if @link.level <= to_kick_link.level
				render :json => create_error(400, t("events.failure.rights")) and return
			end

			to_kick_link.destroy
			render :json => create_response(nil, 200, t("events.success.kicked"))
		rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
			render :json => create_error(400, e.to_s) and return
		end
	end

	swagger_api :upgrade do
		summary "Upgrade a guest"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :volunteer_id, :integer, :required, "Volunteer's id to kick"
		param :query, :event_id, :integer, :required, "Event's id"
		param :query, :rights, :string, :required, "Rights to apply"
		response :ok
	end
	def upgrade
		begin
			if (@link == nil)
				render :json => create_error(400, t("events.failure.rights")) and return
			end

			to_up_link = EventVolunteer.where(event_id: @event.id)
				.where(volunteer_id: @target_volunteer.id).first
			if (to_up_link == nil)
				render :json => create_error(400, t("events.failure.not_guest")) and return
			end

			if @link.level <= to_up_link.level
				render :json => create_error(400, t("events.failure.rights")) and return
			end

			# il se passe quoi si je mets des wrong rights?

			to_up_link.update!({:rights => params[:rights]})
			render :json => create_response(nil, 200, t("events.success.upgraded"))
		rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
			render :json => create_error(400, e.to_s) and return
		end
	end

	swagger_api :join do
		summary "Apply to an event"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :event_id, :integer, :required, "Event's id"
		response :ok
	end
	def join
		begin
			# Check if already guest or if already applied
			if ((EventVolunteer.where(volunteer_id: current_volunteer.id)
						 .where(event_id: @event.id).first != nil) ||
					(Notification.where(notif_type: 'JoinEvent')
						 .where(sender_id: current_volunteer.id)
						 .where(event_id: @event.id).first != nil) ||
					(Notification.where(notif_type: 'InviteGuest')
						 .where(event_id: @event.id)
						 .where(receiver_id: current_volunteer.id).first != nil))
				render :json => create_error(400, t("events.failure.join_link_exist"))
				return
			end

			if @event.private.eql?(false)
				EventVolunteer.create!(volunteer_id: current_volunteer.id,
															 event_id: @event.id,
															 rights: 'member')
				render :json => create_response(t("events.success.join_event"))
				return
			elsif @link.blank?
				# create a notification for the event receiving the request
				notif = Notification.create!(create_join_event)

				# create a link between the notification and each admin of the event
				Volunteer.joins(:event_volunteers)
					.where(event_volunteers: { event_id: @event.id })
					.where("event_volunteers.level > ?", 5)
					.select("volunteers.id").all.each do |volunteer|
					NotificationVolunteer.create!([
																				 volunteer_id: volunteer['id'],
																				 notification_id: notif[0].id,
																				 read: false
																				])
				end

				send_notif_to_socket(notif[0]) unless Rails.env.test?

				render :json => create_response(nil, 200, t("events.success.apply_event")) and return
			end

			render :json => create_error(400, t("events.failure.rights")) and return
		rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
			render :json => create_error(400, e.to_s) and return
		end
	end

	swagger_api :reply_guest do
		summary "Respond to a guest request"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :notif_id, :integer, :required, "Notification's id"
		param :query, :acceptance, :boolean, :required, "true to accept, false otherwise"
		response :ok
	end
	def reply_guest
		begin
			@notif = Notification.find_by!(id: params[:notif_id])

			# Check the rights of the person who's trying to accept a guest
			if ((@link.eql? nil) || (@link.level < EventVolunteer.levels["member"]))
				render :json => create_error(400, t("events.failure.rights")) and return
			end

			guest_id = @notif.sender_id
			event_id = @notif.event_id
			acceptance = params[:acceptance]

			if acceptance
				@notif.notif_type = 'NewGuest'
				@notif.save!
				send_notif_to_socket(@notif) unless Rails.env.test?
				create_guest_link(guest_id, event_id)
			else
				@notif.destroy
			end

			render :json => create_response(t("events.success.reply_guest"))
		rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
			render :json => create_error(400, e.to_s) and return
		end
	end

	swagger_api :invite do
		summary "Invite a volunteer to join the event"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :volunteer_id, :integer, :required, "Volunteer's id"
		param :query, :event_id, :integer, :required, "Event's id"
		response :ok
	end
	def invite
		begin
			# Check if volunteer has the permission to invite a guest in event
			if ((@link.eql? nil) || (@link.level < EventVolunteer.levels["member"]))
				render :json => create_error(400, t("events.failure.rights")) and return
			end

			# Check if target_volunteer is already guest or if already applied
			if ((EventVolunteer.where(volunteer_id: @target_volunteer.id)
						 .where(event_id: @event.id).first != nil) ||
					(Notification.where(notif_type: 'JoinEvent')
						 .where(sender_id: @target_volunteer.id)
						 .where(event_id: @event.id).first != nil) ||
					(Notification.where(notif_type: 'InviteGuest')
						 .where(event_id: @event.id)
						 .where(receiver_id: @target_volunteer.id).first != nil))
				render :json => create_error(400, t("events.failure.invite_link_exist")) and return
			end

			# create a notification for volunteer receiving invitation
			notif = Notification.create!(create_invite_guest)

			send_notif_to_socket(notif[0]) unless Rails.env.test?

			render :json => create_response(t("events.success.invite_guest"))
		rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
			render :json => create_error(400, e.to_s) and return
		end
	end

	swagger_api :reply_invite do
		summary "Respond to an invitation from an event"
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
			if acceptance
				create_guest_link(guest_id, event_id)
			end

			render :json => create_response(nil, 200, t("events.success.reply_invite"))
		rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
			render :json => create_error(400, e.to_s) and return
		end
	end

	swagger_api :leave_event do
		summary "Leave an event"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :event_id, :integer, :required, "Event's id"
		response :ok
	end
	def leave_event
		begin
			event = Event.find_by!(id: params[:event_id])

			link = EventVolunteer.where(:volunteer_id => current_volunteer.id).where(:event_id => event.id).first

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

	swagger_api :invited do
		summary "List all invited volunteers"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :event_id, :integer, :required, "Event's id"
		response :ok
	end
	def invited
		invited_volunteers = Volunteer.joins("INNER JOIN notifications ON notifications.receiver_id=volunteers.id")
			.where("notifications.notif_type='InviteGuest'")
			.where("notifications.event_id=#{@event.id}")
			.select("volunteers.*, notifications.created_at AS sending_date")
		render :json => create_response(invited_volunteers
																		 .as_json(except: [:password,
																											 :created_at, :updated_at]))
	end

	swagger_api :uninvite do
		summary "Remove an invitation"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :event_id, :integer, :required, "Event's id"
		param :query, :volunteer_id, :integer, :required, "Volunteer's id to uninvite"
		response :ok
	end
	def uninvite
		begin
			notif = Notification.where(notif_type: "InviteGuest")
				.where(event_id: @event.id)
				.where(receiver_id: @target_volunteer.id).first

			if notif.blank?
				render :json => create_error(400, t("events.failure.uninvite")) and return
			end

			notif.destroy

			render :json => create_response(t("events.success.uninvited"))
		rescue => e
			render :json => create_error(400, e.to_s)
		end
	end

	swagger_api :unjoin do
		summary "Cancel a joining request"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :event_id, :integer, :required, "Event's id"
		response :ok
	end
	def unjoin
		begin
			notif = current_volunteer.notifications.select(&:is_join_event?).select { |notification| notification.event_id == @event.id }.first

			if notif.blank?
				render json: create_error(400, t("events.failure.unjoin")) and return
			end

			notif.destroy

			render json: create_response(t("events.success.unjoin"))
		rescue => e
			render :json => create_error(400, e.to_s)
		end
	end

	swagger_api :waiting do
		summary "List all volunteers waiting to join the event"
		param :header, 'access-token', :string, :required, "Access token"
		param :header, :client, :string, :required, "Client token"
		param :header, :uid, :string, :required, "Volunteer's uid (email address)"
		param :query, :event_id, :integer, :required, "Event's id"
		response :ok
	end
	def waiting
		waiting_volunteers = Volunteer.joins("INNER JOIN notifications ON notifications.sender_id=volunteers.id")
			.where("notifications.notif_type='JoinEvent'")
			.where("notifications.event_id=#{@event.id}")
			.select("volunteers.*, notifications.created_at AS sending_date, notifications.id AS notif_id")
		render :json => create_response(waiting_volunteers
																		 .as_json(except: [:password,
																											 :created_at, :updated_at]))
	end

	private
	def set_event
		begin
			@event = Event.find(params[:event_id])
		rescue
			begin
				notif = Notification.find(params[:notif_id])
				@event = Event.find(notif.event_id)
			rescue
				render :json => create_error(400, t("events.failure.id")), status: 400
			end
		end
	end

	def set_link
		@link = EventVolunteer.where(:volunteer_id => current_volunteer.id).where(:event_id => @event.id).first
	end

	def create_join_event
		[sender_id: current_volunteer.id,
		 event_id: @event.id,
		 notif_type: 'JoinEvent']
	end

	def create_invite_guest
		[event_id: @event.id,
		 sender_id: current_volunteer.id,
		 receiver_id: @target_volunteer.id,
		 notif_type: 'InviteGuest']
	end

	def set_target_volunteer
		begin
			@target_volunteer = Volunteer.find_by!(id: params[:volunteer_id])
		rescue
			render :json => create_error(400, t("volunteers.failure.id")) and return
		end
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
		if @link.eql?(nil) || @link.rights.eql?('member')
			render :json => create_error(400, t("events.failure.rights"))
			return false
		end
		return true
	end
end
