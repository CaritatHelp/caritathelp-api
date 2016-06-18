# -*- coding: utf-8 -*-
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Volunteers

robin = Volunteer.create([firstname: 'Robin', lastname: 'Vasseur',
                  mail: 'robin@root.com', password: 'root'])
pierre = Volunteer.create([firstname: 'Pierre', lastname: 'Enjalbert',
                  mail: 'pierre@root.com', password: 'root'])
aude = Volunteer.create([firstname: 'Aude', lastname: 'Sikorav',
                  mail: 'aude@root.com', password: 'root'])
jeremy = Volunteer.create([firstname: 'Jeremy', lastname: 'Gros',
                  mail: 'jeremy@root.com', password: 'root'])
nicolas = Volunteer.create([firstname: 'Nicolas', lastname: 'Temenides',
                  mail: 'nicolas@root.com', password: 'root'])
jerome = Volunteer.create([firstname: 'Jerome', lastname: 'Caudoux',
                  mail: 'jerome@root.com', password: 'root'])

# VFriends

VFriend.create([volunteer_id: robin[0][:id], friend_volunteer_id: pierre[0][:id]])
VFriend.create([volunteer_id: pierre[0][:id], friend_volunteer_id: robin[0][:id]])
VFriend.create([volunteer_id: robin[0][:id], friend_volunteer_id: nicolas[0][:id]])
VFriend.create([volunteer_id: nicolas[0][:id], friend_volunteer_id: robin[0][:id]])

# Assocs

croix_rouge = Assoc.create([name: 'Croix verte', description: 'Croix verte du swag',
                           birthday: '02/12/2015', city: 'Paris',
                           latitude: 9.99, longitude: 9.99])
resto  = Assoc.create([name: "Les resto de l'estomac", description: 'Pour se remplir le bide',
                           birthday: '02/12/2015', city: 'Là-bas',
                           latitude: 9.99, longitude: 9.99])

# AvLinks

AvLink.create([assoc_id: croix_rouge[0][:id], volunteer_id: robin[0][:id], rights: 'owner'])
AvLink.create([assoc_id: croix_rouge[0][:id], volunteer_id: nicolas[0][:id], rights: 'admin'])
AvLink.create([assoc_id: croix_rouge[0][:id], volunteer_id: pierre[0][:id], rights: 'admin'])
AvLink.create([assoc_id: croix_rouge[0][:id], volunteer_id: jeremy[0][:id], rights: 'member'])
AvLink.create([assoc_id: croix_rouge[0][:id], volunteer_id: aude[0][:id], rights: 'member'])
AvLink.create([assoc_id: croix_rouge[0][:id], volunteer_id: jerome[0][:id], rights: 'member'])

AvLink.create([assoc_id: resto[0][:id], volunteer_id: robin[0][:id], rights: 'member'])
AvLink.create([assoc_id: resto[0][:id], volunteer_id: pierre[0][:id], rights: 'owner'])
AvLink.create([assoc_id: resto[0][:id], volunteer_id: aude[0][:id], rights: 'admin'])

# Events

event_one = Event.create([title: 'Soignage de gens', description: 'On va soigner des gens',
                         place: 'Zimbabwe', begin: '21/02/2016', end: '22/02/2016', assoc_id: 1])
event_two = Event.create([title: 'Sauvetage du soldat Ryan',
                          description: 'Pour faire plaisir à sa maman',
                         place: 'Normandie', begin: '06/06/1970', end: '07/06/1970', assoc_id: 1])

event_three = Event.create([title: 'Donnage de miam miam', description: 'bonap',
                         place: 'Paris', begin: '21/07/2016', end: '22/07/2016', assoc_id: 2])
event_four = Event.create([title: 'Soirée Pizza !', description: "Mais seulement avec de l'ananas",
                         place: 'Italie', begin: '01/05/2016', end: '30/12/2016', assoc_id: 2])
event_five = Event.create([title: 'Buffet à volonté', description: 'Sushi Maki Brochette',
                         place: 'Tokyo-Chine', begin: '29/07/2016', end: '30/07/2016', assoc_id: 2])

# EventVolunteers

EventVolunteer.create([event_id: event_one[0][:id], volunteer_id: robin[0][:id], rights: 'host'])
EventVolunteer.create([event_id: event_one[0][:id], volunteer_id: nicolas[0][:id], rights: 'admin'])
EventVolunteer.create([event_id: event_one[0][:id], volunteer_id: pierre[0][:id], rights: 'member'])

EventVolunteer.create([event_id: event_two[0][:id], volunteer_id: nicolas[0][:id], rights: 'host'])
EventVolunteer.create([event_id: event_two[0][:id], volunteer_id: pierre[0][:id], rights: 'admin'])
EventVolunteer.create([event_id: event_two[0][:id], volunteer_id: jeremy[0][:id], rights: 'member'])

EventVolunteer.create([event_id: event_three[0][:id], volunteer_id: robin[0][:id], rights: 'host'])
EventVolunteer.create([event_id: event_four[0][:id], volunteer_id: pierre[0][:id], rights: 'host'])
EventVolunteer.create([event_id: event_five[0][:id], volunteer_id: aude[0][:id], rights: 'host'])

# Chatrooms

chatroom_one = Chatroom.create([name: 'Hi everyone', number_volunteers: 6,
                               number_messages: 6, is_private: false])
chatroom_two = Chatroom.create([name: 'Nico - Rob', number_volunteers: 2,
                               number_messages: 5, is_private: true])

# ChatroomVolunteers

ChatroomVolunteer.create([chatroom_id: chatroom_one[0][:id], volunteer_id: robin[0][:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[0][:id], volunteer_id: pierre[0][:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[0][:id], volunteer_id: nicolas[0][:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[0][:id], volunteer_id: jeremy[0][:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[0][:id], volunteer_id: aude[0][:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[0][:id], volunteer_id: jerome[0][:id]])

ChatroomVolunteer.create([chatroom_id: chatroom_two[0][:id], volunteer_id: robin[0][:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_two[0][:id], volunteer_id: nicolas[0][:id]])

# Messages

Message.create([chatroom_id: chatroom_one[0][:id], volunteer_id: robin[0][:id],
                content: 'Yo mes sous fifres'])
Message.create([chatroom_id: chatroom_one[0][:id], volunteer_id: nicolas[0][:id],
                content: "J'avoue on est trop soumis à toi, Ô Grand Maître Robin"])
Message.create([chatroom_id: chatroom_one[0][:id], volunteer_id: pierre[0][:id],
                content: "Je dirais même plus: Ô Grand Maître Robin Le Magnifique"])
Message.create([chatroom_id: chatroom_one[0][:id], volunteer_id: jeremy[0][:id],
                content: "Robin on t'aime tellement"])
Message.create([chatroom_id: chatroom_one[0][:id], volunteer_id: aude[0][:id],
                content: "En plus tu es tellement beau et intelligent, c'est ouffff"])
Message.create([chatroom_id: chatroom_one[0][:id], volunteer_id: jerome[0][:id],
                content: "Moi j'suis nouveau mais j'dois bien avouer qu'ils ont raison"])

Message.create([chatroom_id: chatroom_two[0][:id], volunteer_id: robin[0][:id],
                content: "Yoyoyo ça va?"])
Message.create([chatroom_id: chatroom_two[0][:id], volunteer_id: nicolas[0][:id],
                content: "Ouais et toi?"])
Message.create([chatroom_id: chatroom_two[0][:id], volunteer_id: robin[0][:id],
                content: "Tranquille, j'ai vu ta mère hier"])
Message.create([chatroom_id: chatroom_two[0][:id], volunteer_id: nicolas[0][:id],
                content: "Où ça?"])
Message.create([chatroom_id: chatroom_two[0][:id], volunteer_id: robin[0][:id],
                content: "Dans mon lit, LOL !"])

# Shelters

Shelter.create([name: 'Super shelter de la mort', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150])
Shelter.create([name: 'Shelter de la mort', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150])
Shelter.create([name: 'Auberge de jeunesse', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150])
Shelter.create([name: 'Shelter du swag', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150])
Shelter.create([name: 'Auberge de vieillesse', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150])

# Notifications
