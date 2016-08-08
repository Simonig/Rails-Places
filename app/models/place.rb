class Place

  attr_accessor :id, :formatted_address, :location, :address_components

    def self.mongo_client
        Mongoid::Clients.default
    end

    def self.collection
        self.mongo_client['place_development.places']
    end
    
    def self.load_all(file_path) 
        file=File.read(file_path)
        file = JSON.parse(file)
        self.collection.insert_many(file)
    end

  def self.find_by_short_name(short_name)
    self.collection.find(:"address_components.short_name"=>short_name)
  end

  def photos (offset = 0, limit = nil)
    id = BSON::ObjectId.from_string(@id)
    result = []
    Photo.mongo_client.database.fs.find(:"metadata.place"=>id).skip(offset).map{|doc| result << Photo.new(doc)}
    return result

  end

  def self.to_places(input)
    places = []
      input.each{|x| places << Place.new(x)}
    return places
  end

  def self.find(id)
    id = BSON::ObjectId.from_string(id)
    doc = self.collection.find("_id" => id).first
    if doc
      puts doc
      return Place.new(doc)
    end

  end
  def self.all(offset = 0, limit = nil)

    result = []
    if limit.nil?
    collection.find.skip(offset).each {|r| result << Place.new(r)}

    else
      collection.find.skip(offset).limit(limit).each {|r| result << Place.new(r)}
    end

    return result
  end

  def destroy
    self.class.collection
        .find(_id: BSON::ObjectId.from_string(@id))
        .delete_one
  end

  def self.get_address_components(sort={:_id=>1}, offset = 0, limit = nil)
    pipe=[]
    pipe << {:$project=>{:address_components=>1, :formatted_address=>1, "geometry.geolocation":1}}
    pipe << {:$unwind=>'$address_components'}
    pipe << {:$sort=>sort} if !sort.nil?
    pipe << {:$skip=>offset} if !offset.nil?
    pipe << {:$limit=>limit} if !limit.nil?

    result = self.collection.aggregate(pipe)

  end

  def self.get_country_names

    result = []
    result << {:$project=>{ "address_components.long_name"=>1, "address_components.types"=>1}}
    result << {:$unwind=>'$address_components'}
    result << {:$match=>{"address_components.types" =>'country'}}
    result << {:$group=>{ :_id => "$address_components.long_name"}}
    results = collection.aggregate(result)

    return    results.to_a.map {|h| h[:_id]}
  end

  def self.find_ids_by_country_code (country_code)

    result = collection.aggregate([{:$match=>{"address_components.short_name" => country_code }}])
    return result.map {|doc| doc[:_id].to_s}

  end
  def self.create_indexes

    collection.indexes.create_one({"geometry.geolocation": Mongo::Index::GEO2DSPHERE})

  end

  def self.remove_indexes
    collection.indexes.drop_one('geometry.geolocation':Mongo::Index::GEO2DSPHERE)

  end

  def self.near (point, max_meters=nil)

    near_query={:$geometry=>point.to_hash}

    near_query[:$maxDistance]=max_meters if max_meters

    collection.find(:"geometry.geolocation"=>{:$near=>near_query})

  end

  def near(max_meters=nil)

   Place.to_places(Place.near(@location, max_meters))

  end


    def initialize(hash = {})
      @address_components = []
      @id = hash[:_id].to_s
      hash[:address_components].each{|x| @address_components << AddressComponent.new(x)} if hash[:address_components]
      @formatted_address = hash[:formatted_address]
      @location =  Point.new(hash[:geometry][:geolocation])
    end

end