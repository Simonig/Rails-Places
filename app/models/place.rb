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
      places << input.each{ |x| Place.new(x)}
    return places
  end


    def initialize(hash = {})
      @address_components = []
      @id = hash[:_id].to_s
      hash[:address_components].each{|x| @address_components << AddressComponent.new(x)}

      @formatted_address = hash[:formatted_address]
      @location =  Point.new(hash[:geometry][:location])


    end

end