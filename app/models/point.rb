class Point
    attr_accessor :latitude, :longitude
    
    def to_hash
        hash = {:type => 'Point', :coordinates => [@longitude, @latitude]}
    end

 
def initialize(params={})
    if params[:coordinates]
        @longitude=params[:coordinates][0]
        @latitude=params[:coordinates][1]
    else 
      @longitude=params[:lng]
      @latitude=params[:lat]
    end
  end

    
end