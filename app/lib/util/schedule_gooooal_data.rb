
require 'rubygems'
require 'hpricot'

require 'mysql/match'
require 'mysql/team'
require 'mysql/schedule'

require 'util/common'

module Huuuunt
  module ScheduleGooooalData

    include Huuuunt::Common

    def self.included(base)
      base.extend Huuuunt::ScheduleGooooalData
    end

    def schedule_data_file(season, match_id, phase, path)
      # 创建season目录，如2008或2008-2009
      # 创建match_id目录，如英超创建目录36
      # 目录结构：../data/matches/2008-2009/36/1.htm
      unless File.directory?(File.expand_path("#{season}/", path))
        FileUtils.mkdir(File.expand_path("#{season}/", path))
      end
      unless File.directory?(File.expand_path("#{season}/#{match_id}/", path))
        FileUtils.mkdir(File.expand_path("#{season}/#{match_id}/", path))
      end
      schedule_file_path = File.expand_path("#{season}/#{match_id}/#{phase}", path)
      return schedule_file_path
    end

    def schedule_data_file_exist?(season, gooooal_match_id, phase, path)
      schedule_file_path = File.expand_path("#{season}/#{gooooal_match_id}/#{phase}", path)
      return schedule_file_path if File.exist?(schedule_file_path)
      return FALSE
    end

    # 输入的season只有一种格式，即2010，match_set是match_id的数组
    def schedule_match_phase_loop(season, match_set)
      # 依次处理每个赛事
      match_set.each do |match_id|
        # 获取当前赛事的赛季轮次
        phases = Match.get_gooooal_phases(season, match_id)
        gooooal_match_id = Match.get_gooooal_match_id(match_id)

        # 依次处理每个轮次的数据
        1.upto(phases) do |phase_id|
          yield match_id, gooooal_match_id, phase_id
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

