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
      return
    end
    gps = EXIFR::JPEG.new(@contents).gps
    description = {}
    description[:content_type]= "image/jpeg"
    description[:metadata] = {}
    description[:metadata][:location] = Point.new(:lng=>gps.longitude, :lat=>gps.latitude).to_hash

    grid_file = Mongo::Grid::File.new(@contents.read, description )
    id = self.class.mongo_client.database.fs.insert_one(grid_file)
    @id=id.to_s

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
