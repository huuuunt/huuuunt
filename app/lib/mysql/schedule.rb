
require 'mysql/driver'

class Schedule < ActiveRecord::Base
  def self.schedule_exist?(season, match_id, phase_id, team1_id, team2_id)
    where("season=:season AND phase=:phase_id AND matchno=:match_id AND team1no=:team1_id AND team2no=:team2_id",
          { :season => season, :phase_id => phase_id, :match_id => match_id, :team1_id => team1_id, :team2_id => team2_id}).size > 0
  end

  def self.update_schedule(season, match_id, phase_id, team1_id, team2_id, match_datetime, goal1, goal2, halfgoal1, halfgoal2, finrate, direction, result)
    schedule = where("season=:season AND phase=:phase_id AND matchno=:match_id AND team1no=:team1_id AND team2no=:team2_id",
                    { :season => season, :phase_id => phase_id, :match_id => match_id, :team1_id => team1_id, :team2_id => team2_id}).first
    #return unless schedule
    schedule.matchdt = match_datetime
    schedule.goal1 = goal1
    schedule.goal2 = goal2
    schedule.halfgoal1 = halfgoal1
    schedule.halfgoal2 = halfgoal2
    schedule.finrate = finrate
    schedule.direction = direction
    schedule.result = result

    schedule.save
  end

  def self.get_distinct_teams(season, match_id)
    find_by_sql("select distinct team1no from #{$tab['schedule']} where season='#{season}' and matchno=#{match_id}")
  end

  def self.get_finished_matches(season, match_id)
    # 按照matchdt降序排列，用于确保每支球队的近6场的历史记录准确
    find_by_sql("select phase,matchdt,team1no,team2no,halfgoal1,halfgoal2,goal1,goal2,finrate,direction,result
                    from #{$tab['schedule']}
                  where season='#{season}' and matchno=#{match_id} and goal1 is not null and goal2 is not null
                    order by matchdt desc")
  end

  def self.get_finished_matches_by_matchdt_asc(season, match_id)
    # 按照matchdt降序排列，用于确保每支球队的近6场的历史记录准确
    find_by_sql("select phase,matchdt,team1no,team2no,halfgoal1,halfgoal2,goal1,goal2,finrate,direction,result
                    from #{$tab['schedule']}
                  where season='#{season}' and matchno=#{match_id} and goal1 is not null and goal2 is not null
                    order by matchdt")
  end

  def self.get_schedules_by_season_match(season, match_id)
    where("season=#{season} and matchno=#{match_id} and goal1 is not null and goal2 is not null")
  end

  # 替换team_id
  def self.update_team_id(s_id, d_id)
    update_home_team_id(s_id, d_id)
    update_away_team_id(s_id, d_id)
  end

  def self.update_home_team_id(s_id, d_id)
    where("team1no = #{s_id}").each do |r|
      r.team1no = d_id
      r.save
    end
  end

  def self.update_away_team_id(s_id, d_id)
    where("team2no = #{s_id}").each do |r|
      r.team2no = d_id
      r.save
    end
  end
  
end