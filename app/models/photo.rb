class Photo

  attr_accessor :id, :location
  attr_writer :contents
  attr_reader :id, :location

  def self.mongo_client
    Mongoid::Clients.default
  end

  def persisted?
    !@id.nil?
  end

  def save

    if persisted?
      location = Point.new(@location.to_hash)
      return self.class.mongo_client.database.fs.find(id_criteria)
                    .update_one(":$set" => location.to_hash)

    end
    gps = EXIFR::JPEG.new(@contents).gps
    @contents.rewind
    description = {}
    description[:content_type]= "image/jpeg"
    description[:metadata] = {}
    description[:metadata][:location] = Point.new(:lng=>gps.longitude, :lat=>gps.latitude).to_hash

    grid_file = Mongo::Grid::File.new(@contents.read, description )
    id = self.class.mongo_client.database.fs.insert_one(grid_file)
    @id=id.to_s

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

  def self.id_criteria id
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
    @location = Point.new(hash[:metadata][:location])
    else
      location = {:type => "Point", :coordinates=>[-116.30161960177952, 33.87546081542969]}
      @location = Point.new(location)
    end

  end



end
