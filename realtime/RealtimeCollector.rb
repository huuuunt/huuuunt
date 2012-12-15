require 'open-uri'
require "resque"
require "./config.rb"
require "./League.rb"
require "./Match.rb"
require "./MatchChange.rb"
require "./RealtimeWorkerLeague.rb"
require "./RealtimeWorkerMatch.rb"
require "./RealtimeWorkerMatchChange.rb"
require './timer.rb'

class RealTimeDataCollector
  def initialize
    @matchNUm = 0
    @controlKey = 0
    @leagueList = {}
    @matchList = {}
  end
  
  def refreshChange
    data = open($DataChange + "?" + random_str(8)) {|f|
      f.read
    }
    puts data
    
    domains = data.split(SplitDomain)
    puts domains
    if(!domains[0])
      return
    end
    
    publicDomain = domains[0].split(SplitColumn)
    if($LastTimeStamp > Integer(publicDomain[0]))
      return
    end
    $LastTimeStamp = Integer(publicDomain[0])
    
    tempMatchNUm = publicDomain[2]
    tempControlKey = publicDomain[1]
    
    if(tempControlKey =="2") #全部赛事数据需要重新刷过
      @controlKey=ControlKey
      refreshFull()
      return
    end
    
    if(tempControlKey=="1" && @controlKey!="1")
        @controlKey=ControlKey
        refreshFull()   
        return
    end

    if(!domains[1])
      return
    end
    
    matchChgList = {}
    matchDomain=domains[1].split(SplitRecord);
    matchDomain.each{|matchChg| 
      if(matchChg.length > 5)
          matchChgItem = MatchChange.new(matchChg)
          matchChgList[matchChgItem.gid] = matchChgItem
      end
    }
    Resque.enqueue(RealtimeWorkerMatchChange, matchChgList)    
  end


  def refreshFull
    data = open($DataFullAll + "?" + random_str(8)) {|f|
      f.read
    }
    
    domains = data.split(SplitDomain)
    
    publicDomain=domains[0].split(SplitColumn);
    
    if(Integer(publicDomain[0]) >  $LastTimeStamp)
      $LastTimeStamp = Integer(publicDomain[0])
    end
    
    @matchNum = publicDomain[2]
    @controlKey = publicDomain[1]
    
    leagueDomain=domains[1].split(SplitRecord)
    leagueDomain.each { |league| 
      leagueObj = League.new(league) 
      @leagueList[leagueObj.id] = leagueObj
    }
    
    matchDomain=domains[2].split(SplitRecord)
    matchDomain.each{|match| 
      if(match.length > 5)
          matchItem = Match.new(match)
          leagueItem = @leagueList[matchItem.lid]
          if (leagueItem)
            @matchList[matchItem.gid] = matchItem
            if (leagueItem) 
              leagueItem.matchNum+=1
            end
          end
      end
    }
    Resque.enqueue(RealtimeWorkerLeague, @leagueList)
    Resque.enqueue(RealtimeWorkerMatch, @matchList)          
  end
end


collector = RealTimeDataCollector.new
collector.refreshFull()

Timer.every(5) { |elapsed| 
    collector.refreshChange()
}

