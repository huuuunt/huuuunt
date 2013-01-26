
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
        puts "#{season}, #{match_id}, #{Match.get_match_name_by_id(match_id)}"
        # 获取当前赛事的赛季轮次
        phases = Match.get_gooooal_phases(season, match_id)
        gooooal_match_id = Match.get_gooooal_match_id(match_id)

        # 依次处理每个轮次的数据
        1.upto(phases.to_i) do |phase_id|
          yield match_id, gooooal_match_id, phase_id
        end
      end
    end

    def display_new_teams_finrates(teams, finrates)
      teams.each do |team_name, team_info|
        puts "#{team_name}, #{Match.match_id_map[team_info['match_id']]['name']}, #{team_info['phase_id']}, #{team_info['gooooal_match_id']}"
      end

      finrates.each do |finrate|
        puts "#{finrate}"
      end
    end

    def do_preprocess_team(season, match_id, gooooal_match_id, phase_id, path, new_teams, new_teams_insert, new_finrates)
      schedule_path = schedule_data_file(season, gooooal_match_id, phase_id, path)
      #puts "#{schedule_path}"
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

          #puts "#{team1_name}, #{team2_name}, #{finrate}"

          if finrate and finrate.length>0 and finrate.strip!='-'
            unless gooooal_asia_odd(finrate)
              new_finrates << finrate
              puts "#{gooooal_match_id},#{phase_id},#{i}: finrate: #{finrate}, #{finrate.class}"
            end
          end


          unless Team.team_name_exist?(team1_name)
            new_teams[team1_name] = { "team_name" => team1_name, "match_id" => match_id, "phase_id" => phase_id, "gooooal_match_id" => gooooal_match_id }
            new_teams_insert << { "team_name" => team1_name, "match_id" => match_id, "phase_id" => phase_id, "gooooal_match_id" => gooooal_match_id }
            #puts "#{i}: #{team1_name}, #{Match.match_id_map[match_id]['name']}, #{phase_id}"
          end
          unless Team.team_name_exist?(team2_name)
            new_teams[team2_name] = { "team_name" => team2_name, "match_id" => match_id, "phase_id" => phase_id, "gooooal_match_id" => gooooal_match_id }
            new_teams_insert << { "team_name" => team2_name, "match_id" => match_id, "phase_id" => phase_id, "gooooal_match_id" => gooooal_match_id }
            #puts "#{i}: #{team2_name}, #{Match.match_id_map[match_id]['name']}, #{phase_id}"
          end
        end
      end
    end

    def do_insert_schedule(season, match_id, gooooal_match_id, phase_id, path, schedule)
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
          if goal
            goal1,goal2 = goal.split("-")
          else
            goal1 = nil
            goal2 = nil
          end
          halfgoal = details[8]
          if halfgoal
            halfgoal1,halfgoal2 = halfgoal.split("-")
          else
            halfgoal1 = nil
            halfgoal2 = nil
          end
          s_finrate = details[9]
          finrate = gooooal_asia_odd(s_finrate)
          direction = gooooal_asia_odd_direction(s_finrate)

          result = calc_asia_result(finrate, goal1, goal2)

          finrate = finrate.abs if finrate

          team1_id = Team.get_team_id_by_name(team1_name)
          team2_id = Team.get_team_id_by_name(team2_name)

puts "#{match_id}, #{phase_id},#{match_date},#{match_time},#{season},#{team1_id},#{team2_id},#{goal1},#{goal2},#{halfgoal1},#{halfgoal2},#{finrate},#{direction},#{result}"

          if Schedule.schedule_exist?(season, match_id, phase_id, team1_id, team2_id)
            Schedule.update_schedule(season, match_id, phase_id, team1_id, team2_id, "#{match_date} #{match_time}", goal1, goal2, halfgoal1, halfgoal2, finrate, direction, result)
          else
            schedule << Schedule.new(
                                    :season    => season,
                                    :phase     => phase_id,
                                    :matchdt   => "#{match_date} #{match_time}",
                                    :matchno   => match_id,
                                    :team1no   => team1_id,
                                    :team2no   => team2_id,
                                    :goal1     => goal1,
                                    :goal2     => goal2,
                                    :halfgoal1 => halfgoal1,
                                    :halfgoal2 => halfgoal2,
                                    :finrate   => finrate,
                                    :direction => direction,
                                    :result    => result
                                  )
          end

        end # until f.eof?
      end # File.open(schedule_path, "r")
    end

    def preprocess_team(season, match_set, path)
      new_teams = {}
      new_teams_insert = []
      new_finrates = []
      schedule_match_phase_loop(season, match_set) do |match_id, gooooal_match_id, phase_id|
        continue unless schedule_data_file_exist?(season, gooooal_match_id, phase_id, path)
        do_preprocess_team(season, match_id, gooooal_match_id, phase_id, path, new_teams, new_teams_insert, new_finrates)
      end

      display_new_teams_finrates(new_teams, new_finrates)
      Team.insert_new_team_name(new_teams_insert)
    end

    # 读取csv文件中的赛程数据，导入数据库
    def insert_schedule(season, match_set, path)
      schedule = []
      schedule_match_phase_loop(season, match_set) do |match_id, gooooal_match_id, phase_id|
        next unless schedule_data_file_exist?(season, gooooal_match_id, phase_id, path)
        do_insert_schedule(season, match_id, gooooal_match_id, phase_id, path, schedule)
      end # schedule_match_phase_loop

      Schedule.import(schedule) if schedule.size > 0
    end # function


    # 更新赛程数据
    def schedule_update_loop(data)
      return unless data
      data.each do |item|
        match_id = item['match_id']
        gooooal_match_id = item['gooooal_match_id']
        phases = item['phases']
        phases.each do |phase_id|
          yield match_id, gooooal_match_id, phase_id
        end
      end
    end

    def update_preprocess_team(data, season, path)
      new_teams = {}
      new_teams_insert = []
      new_finrates = []
      schedule_update_loop(data) do |match_id, gooooal_match_id, phase_id|
        #puts "#{season}, #{match_id}, #{gooooal_match_id}, #{phase_id}"
        continue unless schedule_data_file_exist?(season, gooooal_match_id, phase_id, path)
        do_preprocess_team(season, match_id, gooooal_match_id, phase_id, path, new_teams, new_teams_insert, new_finrates)
      end

      display_new_teams_finrates(new_teams, new_finrates)
      Team.insert_new_team_name(new_teams_insert)
    end # function

    def update_schedule(data, season, path)
      schedule = []
      schedule_update_loop(data) do |match_id, gooooal_match_id, phase_id|
        next unless schedule_data_file_exist?(season, gooooal_match_id, phase_id, path)
        do_insert_schedule(season, match_id, gooooal_match_id, phase_id, path, schedule)
      end # schedule_match_phase_loop

      Schedule.import(schedule) if schedule.size > 0
    end #function

  end
end

