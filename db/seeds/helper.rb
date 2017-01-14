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

def join_assoc assoc, volunteer
	Notification.create(sender_id: volunteer[:id], assoc_id: assoc[:id], notif_type: "JoinAssoc")
end

def join_event event, volunteer
	Notification.create(sender_id: volunteer[:id], event_id: event[:id], notif_type: "JoinEvent")
end

def add_news group, volunteer, content, privacy = false
	news = group.news.build(volunteer_id: volunteer[:id], news_type: 'Status', content: content, private: privacy)
	news.save
	news
end

def add_message chatroom, volunteer, content
	Message.create(chatroom_id: chatroom[:id], volunteer_id: volunteer[:id], content: content)
end

def add_comment news, volunteer, content
	comment = news.comments.build(volunteer_id: volunteer[:id], content: content)
	comment.save
end
