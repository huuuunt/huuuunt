require 'open-uri'

SplitDomain="$";
SplitRecord="~";      
SplitColumn="^";
Lang = "zh"

class League
  attr_accessor :id, :name, :tr, :cn, :en, :color, :type, :isZr, :matchNum
  def initialize(leagueRecord)
    infoArr = leagueRecord.split(SplitColumn)
    #@id = 
  end
end

class RealTimeDataCollector
  def initialize
    @lastTimeStamp = 0d
    @matchNUm = 0
    @controlKey = 0
  end
  
  def startCollect
    data = open('http://www.gooooal.com/live/data/ft_all.js') {|f|
      f.read
    }
    
    domains = data.split(SplitDomain)
    
    publicDomain=domains[0].split(SplitColumn);
    
    if(Integer(publicDomain[0]) >  @lastTimeStamp)
      @lastTimeStamp = Integer(publicDomain[0])
    end
    @matchNum = publicDomain[2];
    @controlKey = publicDomain[1]
    
    leagueDomain=domains[1].split(SplitRecord)
    leagueDomain.each { |league| puts league}
    
    
  end

end

collector = RealTimeDataCollector.new
collector.startCollect
