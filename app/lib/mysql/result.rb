
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

  def self.schedule_exist?(season, matchdt, matchno, team1no, team2no, halfgoal1, halfgoal2, goal1, goal2)
    #match_season_type = Match.get_season_type(season, matchno)
    ##puts "#{match_season_type}"
    #
    #if match_season_type == 1
    #  start_date = "#{season}-07-01"
    #  end_date = "#{season.to_i+1}-06-30"
    #else
    #  start_date = "#{season}-01-01"
    #  end_date = "#{season}-12-31"
    #end

    match_date = matchdt.strftime('%Y-%m-%d')
    start_match_datetime = (Date.parse(match_date)-1).strftime('%Y-%m-%d') + " 00:00:00"
    end_match_datetime = (Date.parse(match_date)+1).strftime('%Y-%m-%d') + " 23:59:59"

    #puts "#{start_match_datetime}, #{end_match_datetime}"
    
    result = where("matchdt>\"#{start_match_datetime}\" and matchdt<\"#{end_match_datetime}\" and matchno=#{matchno} and team1no=#{team1no} and team2no=#{team2no}")
    if result.size==0
      puts "NO ITEM : #{season}, #{matchdt.strftime('%Y-%m-%d %H:%M:%S')}, #{matchno}, #{team1no}, #{team2no}, #{Match.get_match_name_by_id(matchno)}, #{Team.get_team_name_by_id(team1no)}, #{Team.get_team_name_by_id(team2no)}"
      return
    end
    result = result.first
    if result.goal1==goal1 and result.goal2==goal2
    else
      #puts "#{result.matchdt.strftime('%Y-%m-%d %H:%M:%S')},#{result.matchno},#{result.team1no},#{result.team2no},#{result.goal1},#{result.goal2},#{result.halfgoal1},#{result.halfgoal2}"
      puts "GOAL NOT CORRECT : #{season}, #{matchdt.strftime('%Y-%m-%d %H:%M:%S')}, #{matchno}, #{team1no}, #{team2no}, #{Match.get_match_name_by_id(matchno)}, #{Team.get_team_name_by_id(team1no)}, #{Team.get_team_name_by_id(team2no)}, [#{result.goal1} vs #{goal1}, #{result.goal2} vs #{goal2}]"
    end
    if result.halfgoal1==halfgoal1 and result.halfgoal2==halfgoal2
    else
      puts "HALF GOAL NOT CORRECT : #{season}, #{matchdt.strftime('%Y-%m-%d %H:%M:%S')}, #{matchno}, #{team1no}, #{team2no}, #{Match.get_match_name_by_id(matchno)}, #{Team.get_team_name_by_id(team1no)}, #{Team.get_team_name_by_id(team2no)}, , [#{result.halfgoal1} vs #{halfgoal1}, #{result.halfgoal2} vs #{halfgoal2}]"
    end

    end
  
end