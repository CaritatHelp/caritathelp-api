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
													latitude: 48.801408, # Versaille
													longitude: 2.1301220000000285,
													password: 'root1234')

aude = Volunteer.create(firstname: 'Aude',
												lastname: 'Sikorav',
												email: 'aude@root.com',
												allowgps: true,
												latitude: 48.8332135, # Paris 14ème
												longitude: 2.3219197,
												password: 'root1234')

jeremy = Volunteer.create(firstname: 'Jeremy',
													lastname: 'Gros',
													email: 'jeremy@root.com',
													allowgps: true,
													latitude: 48.8066706, # kremlin
													longitude: 2.3654136000000108,
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

friendship robin, pierre
friendship robin, nicolas
friendship jeremy, aude
friendship jeremy, pierre
friendship nicolas, pierre

# Assocs

croix_rouge = Assoc.create(name: 'Croix verte',
													 description: 'Croix verte du swag',
													 birthday: '02/12/2015',
													 city: 'Paris',
													 latitude: 48.874942, # Paris 10ème
													 longitude: 2.358640)
resto  = Assoc.create(name: "Les resto de l'estomac",
											description: 'Pour se remplir le bide',
											birthday: '02/12/2015',
											city: 'Paris',
											latitude: 48.856662, # Paris 11ème
											longitude: 2.377175)
frere  = Assoc.create(name: "Les grands frères des pauvres",
											description: 'Association personnes agées',
											birthday: '02/12/1995',
											city: 'Versailles',
											latitude: 48.7949592, # Versailles
											longitude: 2.081339)

# AvLinks

membership croix_rouge, robin, 'owner'
membership croix_rouge, nicolas, 'admin'
membership croix_rouge, pierre, 'admin'
membership croix_rouge, jeremy, 'member'
membership croix_rouge, aude, 'member'
membership croix_rouge, jerome, 'member'

membership resto, robin, 'member'
membership resto, pierre, 'owner'
membership resto, aude, 'admin'

membership frere, aude, 'owner'

# Events

event_one = Event.create(title: 'Soignage de gens',
												 description: 'On va soigner des gens',
												 place: 'Zimbabwe',
												 begin: 2.days.from_now,
												 end: 3.days.from_now,
												 latitude: 48.85661400000001, # Center Paris
												 longitude: 2.3522219000000177,
												 assoc_id: 1)

event_two = Event.create(title: 'Sauvetage du soldat Ryan',
												 description: 'Pour faire plaisir à sa maman',
												 place: 'Normandie',
												 begin: 2.days.from_now,
												 end: 5.days.from_now,
												 latitude: 49.870543, # Saint-Valery-en-Caux
												 longitude: 0.692729,
												 assoc_id: 1)

event_three = Event.create(title: 'Donnage de miam miam',
													 description: 'bonap',
													 place: 'Paris',
													 begin: 22.days.from_now,
													 end: 23.days.from_now,
												   latitude: 48.831373, # Place d'Italie
												   longitude: 2.355711,
													 assoc_id: 2)

event_four = Event.create(title: 'Soirée Pizza !',
													description: "Mais seulement avec de l'ananas",
													place: 'Italie',
													begin: 256.days.from_now,
													end: 258.days.from_now,
												  latitude: 41.902130, # Rome
												  longitude: 12.491259,
													assoc_id: 2)

event_five = Event.create(title: 'Buffet à volonté',
													description: 'Sushi Maki Brochette',
													place: 'Tokyo',
													begin: 2.days.from_now,
													end: 10.days.from_now,
 												  latitude: 35.708990, # Tokyo
 												  longitude: 139.731307,
													assoc_id: 2)

event_frere = Event.create(title: 'Action grand frère',
													 description: 'En cours',
													 place: 'Versailles',
													 begin: 2.days.from_now,
													 end: 10.days.from_now,
 												   latitude: 48.7949592, # Versailles
 												   longitude: 2.081339,
													 assoc_id: frere["id"])

# EventVolunteers

guest event_one, robin, 'host'
guest event_one, nicolas, 'admin'
guest event_one, pierre, 'member'

guest event_two, nicolas, 'host'
guest event_two, pierre, 'admin'
guest event_two, jeremy, 'member'

guest event_three, robin, 'host'
guest event_four, pierre, 'host'
guest event_five, aude, 'host'

guest event_frere, aude, 'host'

# Chatrooms

chatroom_one = Chatroom.create(name: 'Hi everyone', number_volunteers: 6,
															 number_messages: 6, is_private: false)
chatroom_two = Chatroom.create(name: 'Nico - Rob', number_volunteers: 2,
															 number_messages: 5, is_private: true)

# ChatroomVolunteers

chatter chatroom_one, robin
chatter chatroom_one, pierre
chatter chatroom_one, nicolas
chatter chatroom_one, jeremy
chatter chatroom_one, aude
chatter chatroom_one, jerome

chatter chatroom_two, robin
chatter chatroom_two, nicolas

# Messages

add_message chatroom_one, robin, 'Yo mes sous fifres'
add_message chatroom_one, nicolas, "J'avoue on est trop soumis à toi, Ô Grand Maître Robin"
add_message chatroom_one, pierre, "Je dirais même plus: Ô Grand Maître Robin Le Magnifique"
add_message chatroom_one, jeremy, "Robin on t'aime tellement"
add_message chatroom_one, aude, "En plus tu es tellement beau et intelligent, c'est ouffff"
add_message chatroom_one, jerome, "Moi j'suis nouveau mais j'dois bien avouer qu'ils ont raison"

add_message chatroom_two, robin, "Yoyoyo ça va?"
add_message chatroom_two, nicolas, "Ouais et toi?"
add_message chatroom_two, robin, "Tranquille"
add_message chatroom_two, nicolas, "Cool"

# Shelters

Shelter.create([name: 'Un toit pour toi', address: '59 Rue de la Roquette',
							 zipcode: 75011, city: 'Paris', total_places: 200, free_places: 150,
							 description: "Dormir à l'abris toute l'année", assoc_id: 1,
							 latitude: 48.8561268, longitude: 2.3750685])
Shelter.create([name: 'Secours populaire', address: '75bis Boulevard de Clichy',
							 zipcode: 75009, city: 'Paris', total_places: 200, free_places: 150,
							 description: "", assoc_id: 1,
							 latitude: 48.8841419, longitude: 2.3281687])
Shelter.create([name: 'Auberge de la charité', address: '24 Boulevard de Grenelle',
							 zipcode: 75015, city: 'Paris', total_places: 200, free_places: 150,
							 description: "Ouvert à tous", assoc_id: 1,
							 latitude: 48.85291, longitude: 2.287793])
Shelter.create([name: 'Croix rouge', address: '47 Avenue Léon Gambetta',
							 zipcode: 92120, city: 'Montrouge', total_places: 200, free_places: 150,
							 description: "Nourriture et lit gratuit", assoc_id: 1,
							 latitude: 48.8141777, longitude: 2.3188717])
Shelter.create([name: 'Epitech Paris', address: '24 Rue Pasteur',
							 zipcode: 94270, city: 'Le Kremlin-Bicêtre', total_places: 200, free_places: 150,
							 description: "L'école de l'innovation!", assoc_id: 2,
							 latitude: 48.8151016, longitude: 2.3569332])

# Notifications

add_friend robin, jerome
add_friend pierre, jerome
add_friend jerome, jeremy
add_friend jerome, aude
add_friend jerome, nicolas

join_assoc resto, jeremy

# News

add_news event_one, robin, "Aujourd'hui nous comme venu en aide à 3000 personnes"
add_news event_one, robin, "Nous sommes à la recherche de médecins volontaires pour une mission humanitaire de grande ampleur", true

add_news event_two, pierre, "Allons tous sauver le soldat Ryan!"
add_news event_two, pierre, "Youloulou"

add_news event_three, robin, "J'ai faim moi !"

add_news event_four, pierre, "J'adore la pizza !"

add_news event_five, aude, "J'adoooooore les sushis"

add_news robin, robin, "C'est vraiment cool d'être un bénévole!"

super_news = add_news pierre, robin, "Salut Pierre ça va?"

add_news croix_rouge, robin, "Venez aider la Croix Verte!"
add_news croix_rouge, robin, "Nous sommes ouvert à tous!"

# Comment

add_comment super_news, pierre, "Bah oui ça va mais tu sais tu peux me parler en mp plutôt!"
add_comment super_news, robin, "Ah oui!"
