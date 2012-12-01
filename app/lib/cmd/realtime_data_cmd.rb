# encoding: utf-8
require 'open-uri'

SplitDomain="$"
SplitRecord="~"   
SplitColumn="^"
Lang = "cn"
$LastTimeStamp = 0
$MatchStatus = [["","",""], ["未","未",""],["待", "待", "FT ONLY"], ["上", "上", "1st"], ["下", "下", "2nd"], 
              ["半", "半", "HT"], ["完", "完", "Fin"], ["加", "加", "Ext"], ["加1", "加1", "Ext1"], ["加2", "加2", "Ext2"],
              ["完", "完", "ExtF"], ["点", "點", "Penalty"], ["暂", "暂", "Pause"], ["斩", "斬", "Suspend"],
              ["取", "取", "Cancel"], ["改", "改", "Postp"], ["延", "延", "Later"], ["完", "完", "F1"]] 
          
def getStatus(stid) 
  ss = $MatchStatus[Integer(stid)]
  return ss ? ss[0]: ""
end

class League
  attr_accessor :id, :name, :tr, :cn, :en, :color, :type, :isZr, :matchNum
  def initialize(leagueRecord)
    infoArr = leagueRecord.split(SplitColumn)
    @id = infoArr[0]
    @tr = infoArr[1]
    @cn = infoArr[2]
    @en = infoArr[3]
    @color = infoArr[4]
    @type = infoArr[5]
    @isZr = infoArr[6]
    @matchNum = 0
    if ($Lang=="en")
      @name = @en
    elsif ($Lang=="cn")
      @name = @cn
    else
      @name = @tr
    end
  end
  def to_s
    format("%s", @name)
  end
end

class Match
  attr_accessor :gid, :spid, :matchTime, :matchTimeUTC, :stateId, :state, :lid, :stateBody,
                :t1id, :t1tr, :t1en, :t1cn, :t1rate, :t1country, :t1Name,
                :t2id, :t2tr, :t2en, :t2cn, :t2rate, :t2country, :t2Name,
                :t1score, :t2score, :t1scorehalf, :t2scorehalf, :t1score90, :t2score90, :t1score120, :t2score120,
                :t1scorekick, :t2scorekick, :t1scoref, :t2scoref, :t1redcard, :t2redcard, :tv, :hasOdds, :analysisMatchBefore,
                :netual, :place, :runTime, :hasJian, :hasPplv, :mIsZr, :pI的, :lIsZr, :lotIssue, :lotNo,
                :bdIssue, :bdno, :KOTime
  def initialize(matchRecord)
    infoArr=matchRecord.split(SplitColumn)
    @gid = infoArr[0]
    @spid = infoArr[1]         
    @matchTimeUTC = infoArr[2]
    @stateId = infoArr[3]
    @state = getStatus(@stateId)
    @lid = infoArr[4]
    @t1id = infoArr[5]
    @t1tr = infoArr[6]
    @t1cn = infoArr[7]
    @t1en = infoArr[8]
    @t1rate = infoArr[9]
    @t1country = infoArr[10]
    @t2id = infoArr[11]
    @t2tr = infoArr[12]
    @t2cn = infoArr[13]
    @t2en = infoArr[14]
    @t2rate = infoArr[15]
    @t2country = infoArr[16]
    @t1score = infoArr[17]
    @t2score = infoArr[18]
    @t1scorehalf = infoArr[19]
    @t2scorehalf = infoArr[20]
    @t1score90 = infoArr[21]
    @t2score90 = infoArr[22]
    @t1score120 = infoArr[23]
    @t2score120 = infoArr[24]
    @t1scorekick = infoArr[25]
    @t2scorekick = infoArr[26]
    @t1redcard = infoArr[27]
    @t2redcard = infoArr[28]
    @t1scoref = infoArr[29]
    @t2scoref = infoArr[30]
    @tv = infoArr[31]
    @hasOdds = infoArr[32]
    @analysisMatchBefore = infoArr[34]
    @netual = infoArr[35]
    @place = infoArr[36]
    @hasJian = infoArr[39]
    @hasPplv = infoArr[40]
    @mIsZr = infoArr[41]
    @pId = infoArr[42]
    @lIsZr = ""
    @lotIssue = ""
    @lotNo = ""
    if (infoArr[37])
      lli = infoArr[37].split(",")
      @lotIssue = lli[0]
      @lotNo = lli[1]
    end
    
    @bdIssue = "";
    @bdNo = "";
    if(infoArr[38])
        lli = infoArr[38].split(",")
        @bdIssue = lli[0];
        @bdNo = lli[1];
    end
    
    @KOTime = @matchTime
    if(infoArr.length >= 34)
     #@KOTime = DateTime.new(infoArr[33]*1000)
    end
    
    if($Lang=="en")
      @t1Name=@t1en
      @t2Name=@t2en
    elsif($Lang=="cn")
      @t1Name=@t1cn
      @t2Name=@t2cn
    else
      @t1Name=@t1tr
      @t2Name=@t2tr
    end
    
    if(@stateId=="3")
      @runTime = Integer(($lastTimeStamp-infoArr[2])/60)
      if(@runTime<0)
        @runTime=0
      end
    elsif (@StateId=="4")
      @runTime = Integer(($lastTimeStamp-infoArr[2])/60)+45;
      if(@runTime<46)
        @runTime=46
      end
    end
    if(@stateId=="1"||@stateId=="14"||@stateId=="15")#@state==""||@state=="取"||@state=="改"
      @t1score=""
      @t2score=""
      @t1scorehalf=""
      @t2scorehalf=""
    elsif(@stateId=="2")#/*@state=="待"*/)
      @t1score="?"
      @t2score="?"
      @t1scorehalf="?"
      @t2scorehalf="?"
    end
    
    if(@stateId=="1")
      @stateBody="no";
    elsif(@stateId=="6"||
      @stateId=="15"||
      @stateId=="14"||
      @stateId=="13"||
      @stateId=="2")
          #/*@state=="完"||
      #@state=="改"||
      #@state=="取"||
      #@state=="斩"||
      #@state=="待"*/)
      @stateBody="fi"
    else
      @stateBody="li"
    end
    
    if(@stateId=="6") 
      if(@t1scorekick!="" && @t2scorekick!="")
        @state += "(点)";
      elsif(@t1score120!="" && @t2Score120!="")
        @state += "(加)";
      end
    end
  end
  
  def to_s 
    format("%s VS %s", @t1Name, @t2Name)
  end
  
end

class RealTimeDataCollector
  def initialize
    @matchNUm = 0
    @controlKey = 0
    @leagueList = {}
    @matchList = {}
  end
  
  def startCollect
    data = open('http://www.gooooal.com/live/data/ft_all.js') {|f|
      f.read
    }
    
    domains = data.split(SplitDomain)
    
    publicDomain=domains[0].split(SplitColumn);
    
    if(Integer(publicDomain[0]) >  $LastTimeStamp)
      $LastTimeStamp = Integer(publicDomain[0])
    end
    
    @matchNum = publicDomain[2];
    @controlKey = publicDomain[1]
    
    leagueDomain=domains[1].split(SplitRecord)
    leagueDomain.each { |league| 
      leagueObj = League.new(league) 
      @leagueList[leagueObj.id] = leagueObj
     }
    
    @leagueList.each { | league | puts league[1] }
    
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
    @matchList.each { | match | puts match[1] }
  end

end

collector = RealTimeDataCollector.new
collector.startCollect
