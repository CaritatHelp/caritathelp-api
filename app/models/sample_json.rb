class SampleJson < ActiveRecord::Base
  def self.volunteers(filename)
    File.open("#{Rails.root}/public/samples_json/volunteers/"+filename+".json").read
  end

  def self.assocs(filename)
    File.open("#{Rails.root}/public/samples_json/assocs/"+filename+".json").read
  end

  def self.login(filename)
    File.open("#{Rails.root}/public/samples_json/login/"+filename+".json").read
  end

  def self.logout(filename)
    File.open("#{Rails.root}/public/samples_json/logout/"+filename+".json").read
  end

  def self.notifications(filename)
    File.open("#{Rails.root}/public/samples_json/notifications/"+filename+".json").read
  end

  def self.membership(filename)
    File.open("#{Rails.root}/public/samples_json/membership/"+filename+".json").read
  end

  def self.friendship(filename)
    File.open("#{Rails.root}/public/samples_json/friendship/"+filename+".json").read
  end

  def self.events(filename)
    File.open("#{Rails.root}/public/samples_json/events/"+filename+".json").read
  end

  def self.guests(filename)
    File.open("#{Rails.root}/public/samples_json/guests/"+filename+".json").read
  end

  def self.news(filename)
    File.open("#{Rails.root}/public/samples_json/news/"+filename+".json").read
  end
end
