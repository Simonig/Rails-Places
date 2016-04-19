class Place

  attr_accessor :_id, :formatted_address, :location, :address_components

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

    def initialize(hash={})
      @_id = hash[:_id].to_s
      @address_components = hash[:address_components]
      @formatted_address = hash[:formatted_address]
      @geometry = Point.new(hash[:geometry][:location])


    end

end