
require 'mysql/driver'
require 'util/date_tool'
require 'util/common'

class Result < ActiveRecord::Base

  include Huuuunt::DateTool
  include Huuuunt::Common
  
  # 获取当前需要更新的赛果数据的开始日期，格式 2012-10-10  
  def self.lastest_date(format)
    latest_datetime = maximum('matchdt').strftime('%Y-%m-%d %H:%M:%S')

    return latest_date_format(latest_datetime, format)
  end

  def self.match_exist?(matchinfono)
    results = where("matchinfono = ?", matchinfono)
    if results.size == 0
      return false
    else
      return true
    end
  end

  # 替换team_id
  def self.update_team_id(s_id, d_id)
    update_home_team_id(s_id, d_id)
    update_away_team_id(s_id, d_id)
  end

  def self.update_home_team_id(s_id, d_id)
    where("team1no = #{s_id}").each do |r|
      datetime = r.matchdt.strftime('%Y-%m-%d %H:%M:%S')
      new_matchinfono = create_matchinfono2(datetime, r.matchno, d_id, r.team2no)
      r.matchinfono = new_matchinfono
      r.team1no = d_id
      r.save
    end
  end

  def self.update_away_team_id(s_id, d_id)
    where("team2no = #{s_id}").each do |r|
      datetime = r.matchdt.strftime('%Y-%m-%d %H:%M:%S')
      new_matchinfono = create_matchinfono2(datetime, r.matchno, r.team1no, d_id)
      r.matchinfono = new_matchinfono
      r.team2no = d_id
      r.save
    end
  end
  
end