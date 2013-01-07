
require 'rubygems'
require 'hpricot'

require 'mysql/match'
require 'mysql/team'
require 'mysql/score'
require 'mysql/schedule'

require 'util/common'

module Huuuunt
  module ScoreData

    include Huuuunt::Common

    def self.included(base)
      base.extend Huuuunt::ScoreData
    end

    # 输入的season只有一种格式，即2010，match_set是match_id的数组
    def calculate_score(season, match_set)
      match_set.each do |match_id|
        h_home = {}
        h_away = {}
        scores = {}
        scores6 = {}

        # 初始化
        teams = Schedule.get_distinct_teams(season, match_id)
        teams.each do |teamno|
          team_id = teamno[0].to_i
          h_home[team_id] = [0,0,0,0,0,0,0,"",0]
          h_away[team_id] = [0,0,0,0,0,0,0,"",0]
          scores[team_id] = [0,0,0,0,0,0,0,"",0]
          scores6[team_id] = [0,0,0,0,0,0,0,"",0]
        end

        # 从赛程中读取出已经完成的比赛
        matches_arr = Schedule.get_finished_matches(season, match_id)

        # 从赛事数据中分别统计出主场球队的情况和客场球队的情况
        matches_arr.each do |item|
          team1no = item[1].to_i
          team2no = item[2].to_i
          goal1 = item[5].to_i
          goal2 = item[6].to_i

          result1 = 0
          result2 = 0
          wincnt1 = 0
          wincnt2 = 0
          deucecnt1 = 0
          deucecnt2 = 0
          losscnt1 = 0
          losscnt2 = 0
          if goal1 > goal2
            result1 = 3
            result2 = 0
            wincnt1 = 1
            losscnt2 = 1
          elsif goal1 == goal2
            result1 = 1
            result2 = 1
            deucecnt1 = 1
            deucecnt2  =1
          else
            result1 = 0
            result2 = 3
            losscnt1 = 1
            wincnt2 = 1
          end
          # 统计主场球队数据
          if h_home.has_key?(team1no)
            h_home[team1no][0] = h_home[team1no][0] + result1
            h_home[team1no][1] = h_home[team1no][1] + goal1
            h_home[team1no][2] = h_home[team1no][2] + goal1-goal2
            h_home[team1no][3] = h_home[team1no][3] + wincnt1
            h_home[team1no][4] = h_home[team1no][4] + deucecnt1
            h_home[team1no][5] = h_home[team1no][5] + losscnt1
            h_home[team1no][6] = h_home[team1no][6] + 1
            h_home[team1no][7] = h_home[team1no][7] + "#{result1}"
            h_home[team1no][8] = h_home[team1no][8] + goal2
          else
            puts "#{team1no} has error!"
            #h_home[team1no] = [result1, goal1, goal1-goal2, wincnt1, deucecnt1, losscnt1, 1]
          end
          # 统计客场球队数据
          if h_away.has_key?(team2no)
            h_away[team2no][0] = h_away[team2no][0] + result2
            h_away[team2no][1] = h_away[team2no][1] + goal2
            h_away[team2no][2] = h_away[team2no][2] + goal2-goal1
            h_away[team2no][3] = h_away[team2no][3] + wincnt2
            h_away[team2no][4] = h_away[team2no][4] + deucecnt2
            h_away[team2no][5] = h_away[team2no][5] + losscnt2
            h_away[team2no][6] = h_away[team2no][6] + 1
            h_away[team2no][7] = h_away[team2no][7] + "#{result2}"
            h_away[team2no][8] = h_away[team2no][8] + goal1
          else
            puts "#{team2no} has error!"
            #h_away[team2no] = [result2, goal2, goal2-goal1, wincnt2, deucecnt2, losscnt2, 1]
          end
          # 将主场数据加入总场次统计数据中
          if scores.has_key?(team1no)
            scores[team1no][0] = scores[team1no][0] + result1
            scores[team1no][1] = scores[team1no][1] + goal1
            scores[team1no][2] = scores[team1no][2] + goal1-goal2
            scores[team1no][3] = scores[team1no][3] + wincnt1
            scores[team1no][4] = scores[team1no][4] + deucecnt1
            scores[team1no][5] = scores[team1no][5] + losscnt1
            scores[team1no][6] = scores[team1no][6] + 1
            scores[team1no][7] = scores[team1no][7] + "#{result1}"
            scores[team1no][8] = scores[team1no][8] + goal2
          end
          # 将客场数据加入总场次统计数据中
          if scores.has_key?(team2no)
            scores[team2no][0] = scores[team2no][0] + result2
            scores[team2no][1] = scores[team2no][1] + goal2
            scores[team2no][2] = scores[team2no][2] + goal2-goal1
            scores[team2no][3] = scores[team2no][3] + wincnt2
            scores[team2no][4] = scores[team2no][4] + deucecnt2
            scores[team2no][5] = scores[team2no][5] + losscnt2
            scores[team2no][6] = scores[team2no][6] + 1
            scores[team2no][7] = scores[team2no][7] + "#{result2}"
            scores[team2no][8] = scores[team2no][8] + goal1
          end
          # 如果主场球队总场次达到6场
          if scores[team1no][6] == 6
            scores6[team1no] = [
                  scores[team1no][0],scores[team1no][1],scores[team1no][2],
                  scores[team1no][3],scores[team1no][4],scores[team1no][5],
                  6, scores[team1no][7], scores[team1no][8]
            ]
          end
          # 如果客场球队总场次达到6场
          if scores[team2no][6] == 6
            scores6[team2no] = [
                  scores[team2no][0],scores[team2no][1],scores[team2no][2],
                  scores[team2no][3],scores[team2no][4],scores[team2no][5],
                  6, scores[team2no][7], scores[team2no][8]
            ]
          end
        end

        # 如果最近6场统计数据为空，则认为总场次未满6场，因此直接从总场次中获取数据
        scores6.each_key do |key|
          if scores6[key][6] == 0
            scores6[key][0] = scores[key][0]
            scores6[key][1] = scores[key][1]
            scores6[key][2] = scores[key][2]
            scores6[key][3] = scores[key][3]
            scores6[key][4] = scores[key][4]
            scores6[key][5] = scores[key][5]
            scores6[key][6] = scores[key][6]
            scores6[key][7] = scores[key][7]
            scores6[key][8] = scores[key][8]
          end
        end

        # 插入或更新积分榜数据
        scores.each_key do |key|
          @mysql.deal_scores_all(match_id, season, key,
                scores[key][0], scores[key][6], scores[key][3], scores[key][4], scores[key][5],
                scores[key][1], scores[key][8], scores[key][2],
                scores6[key][0], scores6[key][6], scores6[key][3], scores6[key][4], scores6[key][5],
                scores6[key][1], scores6[key][8], scores6[key][2],
                h_home[key][0], h_home[key][6], h_home[key][3], h_home[key][4], h_home[key][5],
                h_home[key][1], h_home[key][8], h_home[key][2],
                h_away[key][0], h_away[key][6], h_away[key][3], h_away[key][4], h_away[key][5],
                h_away[key][1], h_away[key][8], h_away[key][2],
                scores6[key][7]
              )
        end

      end
    end

    def display_new_teams_finrates(teams, finrates)
      teams.each do |team|
        puts "#{team['team_name']}, #{Match.match_id_map[team['match_id']]['name']}, #{team['phase_id']}"
      end

      finrates.each do |finrate|
        puts "#{finrate}"
      end
    end

    def preprocess_team(season, match_set, path)
      new_teams = []
      new_finrates = []
      schedule_match_phase_loop(season, match_set) do |match_id, gooooal_match_id, phase_id|
        continue unless schedule_data_file_exist?(season, gooooal_match_id, phase_id, path)
        schedule_path = schedule_data_file(season, gooooal_match_id, phase_id, path)
        File.open(schedule_path, "r") do |f|
          i = 0
          until f.eof?
            match = f.readline
            i = i + 1
            next if i==1
            details = match.split(' ')

            team1_name = details[5]
            team2_name = details[7]
            finrate = details[9]

            unless gooooal_asia_odd(finrate)
              new_finrates << finrate
            end

            unless Team.team_name_exist?(team1_name)
              new_teams << { "team_name" => team1_name, "match_id" => match_id, "phase_id" => phase_id }
            end
            unless Team.team_name_exist?(team2_name)
              new_teams << { "team_name" => team2_name, "match_id" => match_id, "phase_id" => phase_id }
            end
          end
        end
      end

      display_new_teams_finrates(new_teams, new_finrates)
    end

    # 读取csv文件中的赛程数据，导入数据库
    def insert_schedule(season, match_set, path)
      schedule = []
      schedule_match_phase_loop(season, match_set) do |match_id, gooooal_match_id, phase_id|
        continue unless schedule_data_file_exist?(season, gooooal_match_id, phase_id, path)
        schedule_path = schedule_data_file(season, gooooal_match_id, phase_id, path)
        File.open(schedule_path, "r") do |f|
          i = 0
          until f.eof?
            match = f.readline
            i = i + 1
            next if i==1
            details = match.split(' ')

            phase = details[0]
            match_date = details[2]
            match_time = details[3]
            team1_name = details[5]
            team2_name = details[7]
            goal = details[6]
            goal1,goal2 = goal.split("-")
            halfgoal = details[8]
            halfgoal1,halfgoal2 = halfgoal.split("-")
            s_finrate = details[9]
            finrate = gooooal_asia_odd(s_finrate)
            direction = gooooal_asia_odd_direction(s_finrate)

            result = calc_asia_result(finrate, goal1, goal2)

            team1_id = Team.get_team_id_by_name(team1_name)
            team2_id = Team.get_team_id_by_name(team2_name)

#puts "#{phase_id},#{match_date},#{match_time},#{season},#{team1_id},#{team2_id},#{goal1},#{goal2},#{halfgoal1},#{halfgoal2},#{finrate},#{direction},#{result}"

            if Schedule.schedule_exist?(season, match_id, phase_id, team1_id, team2_id)
              Schedule.update_schedule(season, match_id, phase_id, team1_id, team2_id, "#{match_date} #{match_time}", goal1, goal2, halfgoal1, halfgoal2, finrate, direction, result)
            else
              schedule << Schedule.new(
                                      :matchyear => season,
                                      :phase     => phase_id,
                                      :matchdt   => "#{match_date} #{match_time}",
                                      :matchno   => match_id,
                                      :team1no   => team1_id,
                                      :team2no   => team2_id,
                                      :goal1     => goal1,
                                      :goal2     => goal2,
                                      :halfgoal1 => halfgoal1,
                                      :halfgoal2 => halfgoal2,
                                      :finrate   => finrate.abs,
                                      :direction => direction,
                                      :result    => result
                                    )
            end

          end
        end
        exit
      end

      Schedule.import(schedule) if schedule.size > 0
    end

  end
end

