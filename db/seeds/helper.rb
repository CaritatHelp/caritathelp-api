def friendship volunteer, friend
	VFriend.create(volunteer_id: volunteer[:id], friend_volunteer_id: friend[:id])
	VFriend.create(volunteer_id: friend[:id], friend_volunteer_id: volunteer[:id])
end

def membership assoc, volunteer, rights
	AvLink.create(assoc_id: assoc[:id], volunteer_id: volunteer[:id], rights: rights)
end

def guest event, volunteer, rights
	EventVolunteer.create(event_id: event[:id], volunteer_id: volunteer[:id], rights: rights)
end

def chatter chatroom, volunteer
	ChatroomVolunteer.create([chatroom_id: chatroom[:id], volunteer_id: volunteer[:id]])
end

def add_friend sender, receiver
	Notification.create(sender_id: sender[:id], receiver_id: receiver[:id], notif_type: "AddFriend")
end
