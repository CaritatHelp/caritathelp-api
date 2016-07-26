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
                  mail: 'robin@root.com', password: 'root']).first
pierre = Volunteer.create([firstname: 'Pierre', lastname: 'Enjalbert',
                  mail: 'pierre@root.com', password: 'root']).first
aude = Volunteer.create([firstname: 'Aude', lastname: 'Sikorav',
                  mail: 'aude@root.com', password: 'root']).first
jeremy = Volunteer.create([firstname: 'Jeremy', lastname: 'Gros',
                  mail: 'jeremy@root.com', password: 'root']).first
nicolas = Volunteer.create([firstname: 'Nicolas', lastname: 'Temenides',
                  mail: 'nicolas@root.com', password: 'root']).first
jerome = Volunteer.create([firstname: 'Jerome', lastname: 'Caudoux',
                  mail: 'jerome@root.com', password: 'root']).first

# VFriends

VFriend.create([volunteer_id: robin[:id], friend_volunteer_id: pierre[:id]])
VFriend.create([volunteer_id: pierre[:id], friend_volunteer_id: robin[:id]])
VFriend.create([volunteer_id: robin[:id], friend_volunteer_id: nicolas[:id]])
VFriend.create([volunteer_id: nicolas[:id], friend_volunteer_id: robin[:id]])

# Assocs

croix_rouge = Assoc.create([name: 'Croix verte', description: 'Croix verte du swag',
                           birthday: '02/12/2015', city: 'Paris',
                           latitude: 9.99, longitude: 9.99]).first
resto  = Assoc.create([name: "Les resto de l'estomac", description: 'Pour se remplir le bide',
                           birthday: '02/12/2015', city: 'Là-bas',
                           latitude: 9.99, longitude: 9.99]).first

# AvLinks

AvLink.create([assoc_id: croix_rouge[:id], volunteer_id: robin[:id], rights: 'owner'])
AvLink.create([assoc_id: croix_rouge[:id], volunteer_id: nicolas[:id], rights: 'admin'])
AvLink.create([assoc_id: croix_rouge[:id], volunteer_id: pierre[:id], rights: 'admin'])
AvLink.create([assoc_id: croix_rouge[:id], volunteer_id: jeremy[:id], rights: 'member'])
AvLink.create([assoc_id: croix_rouge[:id], volunteer_id: aude[:id], rights: 'member'])
AvLink.create([assoc_id: croix_rouge[:id], volunteer_id: jerome[:id], rights: 'member'])

AvLink.create([assoc_id: resto[:id], volunteer_id: robin[:id], rights: 'member'])
AvLink.create([assoc_id: resto[:id], volunteer_id: pierre[:id], rights: 'owner'])
AvLink.create([assoc_id: resto[:id], volunteer_id: aude[:id], rights: 'admin'])

# Events

event_one = Event.create([title: 'Soignage de gens', description: 'On va soigner des gens',
                         place: 'Zimbabwe', begin: '21/02/2016', end: '22/02/2016', assoc_id: 1,
                         assoc_name: croix_rouge[:name]]).first
event_two = Event.create([title: 'Sauvetage du soldat Ryan',
                          description: 'Pour faire plaisir à sa maman',
                         place: 'Normandie', begin: '06/06/1970', end: '07/06/1970', assoc_id: 1,
                         assoc_name: croix_rouge[:name]]).first
event_three = Event.create([title: 'Donnage de miam miam', description: 'bonap',
                         place: 'Paris', begin: '21/07/2016', end: '22/07/2016', assoc_id: 2,
                         assoc_name: resto[:name]]).first
event_four = Event.create([title: 'Soirée Pizza !', description: "Mais seulement avec de l'ananas",
                         place: 'Italie', begin: '01/05/2016', end: '30/12/2016', assoc_id: 2,
                         assoc_name: resto[:name]]).first
event_five = Event.create([title: 'Buffet à volonté', description: 'Sushi Maki Brochette',
                         place: 'Tokyo-Chine', begin: '29/07/2016', end: '30/07/2016', assoc_id: 2,
                         assoc_name: resto[:name]]).first

# EventVolunteers

EventVolunteer.create([event_id: event_one[:id], volunteer_id: robin[:id], rights: 'host'])
EventVolunteer.create([event_id: event_one[:id], volunteer_id: nicolas[:id], rights: 'admin'])
EventVolunteer.create([event_id: event_one[:id], volunteer_id: pierre[:id], rights: 'member'])

EventVolunteer.create([event_id: event_two[:id], volunteer_id: nicolas[:id], rights: 'host'])
EventVolunteer.create([event_id: event_two[:id], volunteer_id: pierre[:id], rights: 'admin'])
EventVolunteer.create([event_id: event_two[:id], volunteer_id: jeremy[:id], rights: 'member'])

EventVolunteer.create([event_id: event_three[:id], volunteer_id: robin[:id], rights: 'host'])
EventVolunteer.create([event_id: event_four[:id], volunteer_id: pierre[:id], rights: 'host'])
EventVolunteer.create([event_id: event_five[:id], volunteer_id: aude[:id], rights: 'host'])

# Chatrooms

chatroom_one = Chatroom.create([name: 'Hi everyone', number_volunteers: 6,
                               number_messages: 6, is_private: false]).first
chatroom_two = Chatroom.create([name: 'Nico - Rob', number_volunteers: 2,
                               number_messages: 5, is_private: true]).first

# ChatroomVolunteers

ChatroomVolunteer.create([chatroom_id: chatroom_one[:id], volunteer_id: robin[:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[:id], volunteer_id: pierre[:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[:id], volunteer_id: nicolas[:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[:id], volunteer_id: jeremy[:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[:id], volunteer_id: aude[:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_one[:id], volunteer_id: jerome[:id]])

ChatroomVolunteer.create([chatroom_id: chatroom_two[:id], volunteer_id: robin[:id]])
ChatroomVolunteer.create([chatroom_id: chatroom_two[:id], volunteer_id: nicolas[:id]])

# Messages

Message.create([chatroom_id: chatroom_one[:id], volunteer_id: robin[:id],
                content: 'Yo mes sous fifres'])
Message.create([chatroom_id: chatroom_one[:id], volunteer_id: nicolas[:id],
                content: "J'avoue on est trop soumis à toi, Ô Grand Maître Robin"])
Message.create([chatroom_id: chatroom_one[:id], volunteer_id: pierre[:id],
                content: "Je dirais même plus: Ô Grand Maître Robin Le Magnifique"])
Message.create([chatroom_id: chatroom_one[:id], volunteer_id: jeremy[:id],
                content: "Robin on t'aime tellement"])
Message.create([chatroom_id: chatroom_one[:id], volunteer_id: aude[:id],
                content: "En plus tu es tellement beau et intelligent, c'est ouffff"])
Message.create([chatroom_id: chatroom_one[:id], volunteer_id: jerome[:id],
                content: "Moi j'suis nouveau mais j'dois bien avouer qu'ils ont raison"])

Message.create([chatroom_id: chatroom_two[:id], volunteer_id: robin[:id],
                content: "Yoyoyo ça va?"])
Message.create([chatroom_id: chatroom_two[:id], volunteer_id: nicolas[:id],
                content: "Ouais et toi?"])
Message.create([chatroom_id: chatroom_two[:id], volunteer_id: robin[:id],
                content: "Tranquille, j'ai vu ta mère hier"])
Message.create([chatroom_id: chatroom_two[:id], volunteer_id: nicolas[:id],
                content: "Où ça?"])
Message.create([chatroom_id: chatroom_two[:id], volunteer_id: robin[:id],
                content: "Dans mon lit, LOL !"])

# Shelters

Shelter.create([name: 'Super shelter de la mort', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Yolo", assoc_id: 1])
Shelter.create([name: 'Shelter de la mort', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Yolo", assoc_id: 1])
Shelter.create([name: 'Auberge de jeunesse', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Yolo", assoc_id: 1])
Shelter.create([name: 'Shelter du swag', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Yolo", assoc_id: 2])
Shelter.create([name: 'Auberge de vieillesse', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Yolo", assoc_id: 2])

# Notifications

# News

New::Assoc::AdminPublicWallMessage.create(content: "Donnez des sous à la croix verte et vous deviendrez riche",
                                          assoc_id: croix_rouge.id,
                                          volunteer_id: robin.id)
New::Assoc::AdminPrivateWallMessage.create(content: "Que Dieu vous protège wala",
                                          assoc_id: croix_rouge.id,
                                          volunteer_id: robin.id)
New::Assoc::AdminPublicWallMessage.create(content: "Et donnez nous de la thune encore",
                                          assoc_id: croix_rouge.id,
                                          volunteer_id: robin.id)
New::Assoc::AdminPublicWallMessage.create(content: "Nous on aime manger",
                                          assoc_id: resto.id,
                                          volunteer_id: pierre.id)
New::Assoc::AdminPublicWallMessage.create(content: "Et faire des batailles de bouffe",
                                          assoc_id: resto.id,
                                          volunteer_id: pierre.id)

New::Event::AdminPublicWallMessage.create(content: "Qui veut se faire soigner?",
                                          event_id: event_one.id,
                                          volunteer_id: robin.id)
New::Event::AdminPrivateWallMessage.create(content: "Pourquoi on doit tous risquer sa peau pour un seul soldat?",
                                           event_id: event_two.id,
                                           volunteer_id: nicolas.id)
New::Event::MemberPublicWallMessage.create(content: "PARCE QUE VIVE L'AMERIQUE",
                                           event_id: event_two.id,
                                           volunteer_id: jeremy.id)
New::Event::AdminPublicWallMessage.create(content: "On vous donne à manger mais laissez nous en quand même please",
                                          event_id: event_three.id,
                                          volunteer_id: robin.id)
New::Event::AdminPublicWallMessage.create(content: "Va fencu*** ti amo viva italia sisi",
                                          event_id: event_four.id,
                                          volunteer_id: pierre.id)
New::Event::AdminPublicWallMessage.create(content: "Ah bondou fou foulé dé makihein?",
                                          event_id: event_five.id,
                                          volunteer_id: aude.id)
New::Event::AdminPrivateWallMessage.create(content: "Sushi maki pas cher",
                                           event_id: event_five.id,
                                           volunteer_id: aude.id)

New::Volunteer::SelfWallMessage.create(content: "Je m'appelle Robin et j'aime les pommes", volunteer_id: robin.id)
New::Volunteer::SelfWallMessage.create(content: "Cool non?", volunteer_id: robin.id)
New::Volunteer::SelfWallMessage.create(content: "Je m'apelle Nicolas et je suis moche", volunteer_id: nicolas.id)
New::Volunteer::SelfWallMessage.create(content: "League of Legend c'est trop bien", volunteer_id: nicolas.id)
New::Volunteer::SelfWallMessage.create(content: "J'suis lvl 351 sur overwatch lol", volunteer_id: aude.id)
New::Volunteer::SelfWallMessage.create(content: "Je suis secretement amoureux de Jeremy", volunteer_id: pierre.id)
New::Volunteer::SelfWallMessage.create(content: "Je suis secretement amoureux de Pierre", volunteer_id: jeremy.id)
New::Volunteer::SelfWallMessage.create(content: "J'ai posé une google map sur un site et bim 30 crédits OKLM !", volunteer_id: jerome.id)
New::Volunteer::SelfWallMessage.create(content: "Moi aussi je t'aime Jeremy", volunteer_id: pierre.id)
New::Volunteer::SelfWallMessage.create(content: "Haha je rigolais t'es moche Pierre", volunteer_id: jeremy.id)
