class Haversine < ActiveRecord::Base

  def self.distance(lat1, lng1, lat2, lng2)
    lng_diff = lng2 - lng1
    lat_diff = lat2 - lat1

    a = calc(lat_diff, lat1, lat2, lng_diff)
    dist = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1 - a))
    dist
  end

  def self.to_km(dist)
    dist * 6371
  end

  def self.to_miles(dist)
    dist * 3956
  end

  private

  def self.calc(lat_diff, lat1, lat2, lng_diff)
    (Math.sin(rad(lat_diff)/2))**2 +
      Math.cos(rad(lat1)) *
      Math.cos((rad(lat2))) *
      (Math.sin(rad(lng_diff)/2))**2
  end

  def self.rad(nb)
    nb * Math::PI / 180
  end
end
