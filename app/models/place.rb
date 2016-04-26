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


    def initialize(hash = {})
      @address_components = []
      @id = hash[:_id].to_s
      hash[:address_components].each{|x| @address_components << AddressComponent.new(x)}

      @formatted_address = hash[:formatted_address]
      @location =  Point.new(hash[:geometry][:location])


    end

end