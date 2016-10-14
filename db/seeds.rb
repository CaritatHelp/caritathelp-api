# -*- coding: utf-8 -*-
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Volunteers

robin = Volunteer.create(firstname: 'Robin',
                         lastname: 'Vasseur',
                         mail: 'robin@root.com',
                         allowgps: true,
                         latitude: 49.00841620000001, # home
                         longitude: 2.045980600000007,
                         password: 'root')

pierre = Volunteer.create(firstname: 'Pierre',
                          lastname: 'Enjalbert',
                          mail: 'pierre@root.com',
                          allowgps: true,
                          latitude: 48.8066706, # kremlin
                          longitude: 2.3654136000000108,
                          password: 'root')

aude = Volunteer.create(firstname: 'Aude',
                        lastname: 'Sikorav',
                        mail: 'aude@root.com',
                        allowgps: true,
                        latitude: 37.7749295, # SF
                        longitude: -122.41941550000001,
                        password: 'root')

jeremy = Volunteer.create(firstname: 'Jeremy',
                          lastname: 'Gros',
                          mail: 'jeremy@root.com',
                          allowgps: true,
                          latitude: 48.801408, # Versaille
                          longitude: 2.1301220000000285,
                          password: 'root')

nicolas = Volunteer.create(firstname: 'Nicolas',
                           lastname: 'Temenides',
                           mail: 'nicolas@root.com',
                           allowgps: true,
                           latitude: 43.296482, # Marseille
                           longitude: 5.369779999999992,
                           password: 'root')

jerome = Volunteer.create(firstname: 'Jerome',
                          lastname: 'Caudoux', 
                          mail: 'jerome@root.com',
                          allowgps: true,
                          latitude: 20.593684, # Inde
                          longitude: 78.96288000000004,
                          password: 'root')

# VFriends

VFriend.create(volunteer_id: robin[:id], friend_volunteer_id: pierre[:id])
VFriend.create(volunteer_id: pierre[:id], friend_volunteer_id: robin[:id])
VFriend.create(volunteer_id: robin[:id], friend_volunteer_id: nicolas[:id])
VFriend.create(volunteer_id: nicolas[:id], friend_volunteer_id: robin[:id])

# Assocs

croix_rouge = Assoc.create(name: 'Croix verte',
                           description: 'Croix verte du swag',
                           birthday: '02/12/2015',
                           city: 'Paris',
                           latitude: 9.99,
                           longitude: 9.99)

resto  = Assoc.create(name: "Les resto de l'estomac",
                      description: 'Pour se remplir le bide',
                      birthday: '02/12/2015',
                      city: 'Là-bas',
                      latitude: 9.99,
                      longitude: 9.99)

# AvLinks

AvLink.create(assoc_id: croix_rouge[:id], volunteer_id: robin[:id], rights: 'owner')
AvLink.create(assoc_id: croix_rouge[:id], volunteer_id: nicolas[:id], rights: 'admin')
AvLink.create(assoc_id: croix_rouge[:id], volunteer_id: pierre[:id], rights: 'admin')
AvLink.create(assoc_id: croix_rouge[:id], volunteer_id: jeremy[:id], rights: 'member')
AvLink.create(assoc_id: croix_rouge[:id], volunteer_id: aude[:id], rights: 'member')
AvLink.create(assoc_id: croix_rouge[:id], volunteer_id: jerome[:id], rights: 'member')

AvLink.create(assoc_id: resto[:id], volunteer_id: robin[:id], rights: 'member')
AvLink.create(assoc_id: resto[:id], volunteer_id: pierre[:id], rights: 'owner')
AvLink.create(assoc_id: resto[:id], volunteer_id: aude[:id], rights: 'admin')

# Events

event_one = Event.create(title: 'Soignage de gens',
                         description: 'On va soigner des gens',
                         place: 'Zimbabwe',
                         begin: 2.days.from_now,
                         end: 3.days.from_now,
                         latitude: 48.85661400000001, # center paris
                         longitude: 2.3522219000000177,
                         assoc_id: 1,
                         assoc_name: croix_rouge[:name])

event_two = Event.create(title: 'Sauvetage du soldat Ryan',
                         description: 'Pour faire plaisir à sa maman',
                         place: 'Normandie',
                         begin: 2.days.from_now,
                         end: 5.days.from_now,
                         assoc_id: 1,
                         assoc_name: croix_rouge[:name])

event_three = Event.create(title: 'Donnage de miam miam',
                           description: 'bonap',
                           place: 'Paris',
                           begin: 22.days.from_now,
                           end: 23.days.from_now,
                           assoc_id: 2,
                           assoc_name: resto[:name])

event_four = Event.create(title: 'Soirée Pizza !',
                          description: "Mais seulement avec de l'ananas",
                          place: 'Italie',
                          begin: 256.days.from_now,
                          end: 258.days.from_now,
                          assoc_id: 2,
                          assoc_name: resto[:name])

event_five = Event.create(title: 'Buffet à volonté',
                          description: 'Sushi Maki Brochette',
                          place: 'Tokyo-Chine',
                          begin: 2.days.from_now,
                          end: 10.days.from_now,
                          assoc_id: 2,
                          assoc_name: resto[:name])

# EventVolunteers

EventVolunteer.create(event_id: event_one[:id], volunteer_id: robin[:id], rights: 'host')
EventVolunteer.create(event_id: event_one[:id], volunteer_id: nicolas[:id], rights: 'admin')
EventVolunteer.create(event_id: event_one[:id], volunteer_id: pierre[:id], rights: 'member')

EventVolunteer.create(event_id: event_two[:id], volunteer_id: nicolas[:id], rights: 'host')
EventVolunteer.create(event_id: event_two[:id], volunteer_id: pierre[:id], rights: 'admin')
EventVolunteer.create(event_id: event_two[:id], volunteer_id: jeremy[:id], rights: 'member')

EventVolunteer.create(event_id: event_three[:id], volunteer_id: robin[:id], rights: 'host')
EventVolunteer.create(event_id: event_four[:id], volunteer_id: pierre[:id], rights: 'host')
EventVolunteer.create(event_id: event_five[:id], volunteer_id: aude[:id], rights: 'host')

# Chatrooms

chatroom_one = Chatroom.create(name: 'Hi everyone', number_volunteers: 6,
                               number_messages: 6, is_private: false)
chatroom_two = Chatroom.create(name: 'Nico - Rob', number_volunteers: 2,
                               number_messages: 5, is_private: true)

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
               description: "Yolo", assoc_id: 1])
Shelter.create([name: 'Auberge de vieillesse', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Yolo", assoc_id: 1])

# Notifications

# News

news1 = event_one.news.build(volunteer_id: robin[:id], news_type: 'Status', content: "Toto")
news1.save
news2 = event_one.news.build(volunteer_id: robin[:id], news_type: 'Status', content: "Toto", private: true)
news2.save
