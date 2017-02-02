# API Caritathelp

Caritathelp is the name of our end of studies' project.The purpose of this project was to create a social network dedicated to the world of charity associations.

I was in charge of the API, developped in Ruby on Rails 4.3, with a PostgreSQL database.
My colleagues were in charge of the different clients (Android, iOS, Windows Phone & Web applications).

We started to work on this project during our third year in 2015 and we dropped it after our final defense in January 2017. It was a good training to understand the development of an API, and to start working with Ruby on Rails.
You will find some very bad code at some places, and some good code at some other places, this might testify how I improved during the past 2 years :)

Cheers!

## Gems

#### Devise Token Auth
I used this gem to have a token based authentication system. The clients had to send the token on each request.

#### EventMachine
In order to push some notifications to the clients, I've been building a websocket system with the help of EventMachine.
See websocket/server.rb

#### CarrierWave
This might be the ugliest part of my code, I built an upload file system, it worked, but I never really understood how... This part should be erased :D

#### Swagger Doc
I maintained a real time up to date documentation for the clients with the help of Swagger Doc.

#### Rspec, FactoryGirl, Faker
I wrote some models & controllers tests with Rspec, helped by FactoryGirl for the fixtures and Faker to generate random datas.

