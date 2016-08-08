class Photo

  attr_accessor :id, :location, :place
  attr_writer :contents
  attr_reader :id, :location, :place

  def self.mongo_client
    Mongoid::Clients.default
  end

  def persisted?
    !@id.nil?
  end

  def save

    if persisted?
      return self.class.mongo_client.database.fs.find(id_criteria).update_one(:$set => {"metadata.location" => @location.to_hash}, :$set => {"metadata.place" => @place} )
    end
    gps = EXIFR::JPEG.new(@contents).gps
    @contents.rewind
    description = {}
    description[:content_type]= "image/jpeg"
    description[:metadata] = {}
    description[:metadata][:location] = Point.new(:lng=>gps.longitude, :lat=>gps.latitude).to_hash
    description[:metadata][:place] = @place

    grid_file = Mongo::Grid::File.new(@contents.read, description )
    id = self.class.mongo_client.database.fs.insert_one(grid_file)
    @id=id.to_s

  end
  def place
     return Place.find(@place.to_s) if @place
  end

  def place=(object)
    case
      when  object.is_a?(Place)
        @place=BSON::ObjectId.from_string(object.id)
      when  object.is_a?(String)
        @place = BSON::ObjectId.from_string(object)
      when object.is_a?(BSON::ObjectId)
        @place = object

    end

  end

  def self.find_photos_for_place(place_id)
    place_id = BSON::ObjectId.from_string(place_id.to_s)

    return self.mongo_client.database.fs.find(:"metadata.place"=>place_id)


  end



  def destroy
    self.class.mongo_client.database.fs.find(id_criteria).delete_one
  end

  def self.all(skip = 0, limit = nil)
    files=[]

    if limit.nil?
      mongo_client.database.fs.find.skip(skip).each do |r|
        files << Photo.new(r)
      end
    else
      mongo_client.database.fs.find.skip(skip).limit(limit).each do |r|
        files << Photo.new(r)
      end
    end


    return files

  end

  def self.find(id)
    id = BSON::ObjectId.from_string(id)
    doc = mongo_client.database.fs.find("_id" => id).first
    if doc
      return Photo.new(doc)
    end

  end

  def self.id_criteria (id)
    {_id:BSON::ObjectId.from_string(id)}
  end

  def id_criteria
    self.class.id_criteria @id
  end

  def contents
    f=self.class.mongo_client.database.fs.find_one(id_criteria)

    if f
      buffer = ""
      f.chunks.reduce([]) do |x,chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end

  def find_nearest_place_id (max_meters)

  Place.near(@location, max_meters).limit(1).projection({_id:true}).map{ |u| return u[:_id]}


  end



  def initialize (hash = {})
    @id = hash[:_id].to_s if hash[:_id]
    if hash[:metadata]
      @place = hash[:metadata][:place]
      @location = Point.new(hash[:metadata][:location])
    else
      location = {:type => "Point", :coordinates=>[-116.30161960177952, 33.87546081542969]}
      @location = Point.new(location)
      @place = nil
    end

  end



end
