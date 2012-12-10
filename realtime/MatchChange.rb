# encoding: utf-8
require './config.rb'

class MatchChange
  attr_accessor :gid, :spid, :matchTime, :matchTimeUTC, :stateId, :state , :stateBody,
                :t1score, :t2score, :t1scorehalf, :t2scorehalf, :t1score90, :t2score90, :t1score120, :t2score120,
                :t1scorekick, :t2scorekick, :t1redcard, :t2redcard, :intro, :hasOdds, :runTime
                
  def initialize(matchRecord)
    infoArr=matchRecord.split(SplitColumn)
    @gid = infoArr[0]
    @spid = infoArr[1]         
    @matchTimeUTC = infoArr[2]
    @matchTime = Time.at(Integer(@matchTimeUTC))
    @stateId = infoArr[3]
    @state = getStatus(@stateId)
    @t1score = infoArr[4]
    @t2score = infoArr[5]
    @t1scorehalf = infoArr[6]
    @t2scorehalf = infoArr[7]
    @t1score90 = infoArr[8]
    @t2score90 = infoArr[9]
    @t1score120 = infoArr[10]
    @t2score120 = infoArr[11]
    @t1scorekick = infoArr[12]
    @t2scorekick = infoArr[13]
    @t1redcard = infoArr[14]
    @t2redcard = infoArr[15]
    @intro = infoArr[16]
    @hasOdds = infoArr[19]
    
    if(@stateId=="3")
      @runTime = Integer(($LastTimeStamp-Integer(infoArr[2]))/60)
      if(@runTime<0)
        @runTime=0
      end
    elsif (@StateId=="4")
      @runTime = Integer(($LastTimeStamp-Integer(infoArr[2]))/60)+45;
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
    format("%s VS %s @ %s", @gid, @spid, @matchTime.strftime("%Y-%m-%d %H:%M:%S"))
  end
  
end