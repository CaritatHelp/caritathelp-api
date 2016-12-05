# coding: utf-8
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
                         email: 'robin@root.com',
                         allowgps: true,
                         latitude: 49.00841620000001, # home
                         longitude: 2.045980600000007,
                         password: 'root1234')

pierre = Volunteer.create(firstname: 'Pierre',
                          lastname: 'Enjalbert',
                          email: 'pierre@root.com',
                          allowgps: true,
                          latitude: 48.8066706, # kremlin
                          longitude: 2.3654136000000108,
                          password: 'root1234')

aude = Volunteer.create(firstname: 'Aude',
                        lastname: 'Sikorav',
                        email: 'aude@root.com',
                        allowgps: true,
                        latitude: 37.7749295, # SF
                        longitude: -122.41941550000001,
                        password: 'root1234')

jeremy = Volunteer.create(firstname: 'Jeremy',
                          lastname: 'Gros',
                          email: 'jeremy@root.com',
                          allowgps: true,
                          latitude: 48.801408, # Versaille
                          longitude: 2.1301220000000285,
                          password: 'root1234')

nicolas = Volunteer.create(firstname: 'Nicolas',
                           lastname: 'Temenides',
                           email: 'nicolas@root.com',
                           allowgps: true,
                           latitude: 43.296482, # Marseille
                           longitude: 5.369779999999992,
                           password: 'root1234')

jerome = Volunteer.create(firstname: 'Jerome',
                          lastname: 'Caudoux', 
                          email: 'jerome@root.com',
                          allowgps: true,
                          latitude: 20.593684, # Inde
                          longitude: 78.96288000000004,
                          password: 'root1234')

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
                content: "Tranquille"])
Message.create([chatroom_id: chatroom_two[:id], volunteer_id: nicolas[:id],
                content: "Cool"])

# Shelters

Shelter.create([name: 'Un toit pour toi', address: 'Rue de Paris',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Dormir à l'abris toute l'année", assoc_id: 1])
Shelter.create([name: 'Secours populaire', address: 'Rue voltaire',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "", assoc_id: 1])
Shelter.create([name: 'Auberge de la charité', address: 'Rue du chariton',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Ouvert à tous", assoc_id: 1])
Shelter.create([name: 'Croix rouge', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "Nourriture et lit gratuit", assoc_id: 1])
Shelter.create([name: 'Oyé logement', address: 'Rue du swag',
               zipcode: 75000, city: 'Paris', total_places: 200, free_places: 150,
               description: "", assoc_id: 2])

# Notifications

Notification.create(sender_id: robin[:id], sender_name: robin[:fullname], sender_thumb_path: robin[:thumb_path],
                    receiver_id: jerome[:id], receiver_name: jerome[:fullname], receiver_thumb_path: jerome[:thumb_path],
                    notif_type: "AddFriend")
Notification.create(sender_id: pierre[:id], sender_name: pierre[:fullname], sender_thumb_path: pierre[:thumb_path],
                    receiver_id: jerome[:id], receiver_name: jerome[:fullname], receiver_thumb_path: jerome[:thumb_path],
                    notif_type: "AddFriend")

# News

news1 = event_one.news.build(volunteer_id: robin[:id], volunteer_name: robin[:fullname], volunteer_thumb_path: robin[:thumb_path], news_type: 'Status', content: "Aujourd'hui nous comme venu en aide à 3000 personnes")
news1.save
news2 = event_one.news.build(volunteer_id: robin[:id], volunteer_name: robin[:fullname], volunteer_thumb_path: robin[:thumb_path], news_type: 'Status', content: "Nous sommes à la recherche de médecins volontaires pour une mission humanitaire de grande ampleur", private: true)
news2.save
