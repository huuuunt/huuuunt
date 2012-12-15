# encoding: utf-8
require './config.rb'

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
    format("%s：%d", @name, @matchNum)
  end
end