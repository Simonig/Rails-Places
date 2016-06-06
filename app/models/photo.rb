class Photo

  attr_accessor :id, :location
  attr_reader :id, :location
  attr_writer :contents

  def self.mongo_client
    Mongoid::Clients.default
  end

  def persisted?
   return @id.nil?
  end

  def save
    Rails.logger.debug {"#{self}"}
    if persisted?
      return
    end
    GridFS = {}
    gps = EXIFR::JPEG.new([:contents]).gps

    GridFS[:contentType] =  "image/jpg"



  end


  def initialize (hash = {})
    @id =  hash[:_id].to_s
    @location = Point.new(hash[:metadata][:location])
  end



end
