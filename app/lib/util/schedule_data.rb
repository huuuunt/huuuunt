
require 'rubygems'
require 'hpricot'

require 'mysql/match'
require 'mysql/team'

module Huuuunt
  module ScheduleData
    def self.included(base)
      base.extend Huuuunt::ScheduleData
    end

    def schedule_data_file(season, match_id, phase, path, suffix)
      # 创建season目录，如2008或2008-2009
      # 创建match_id目录，如英超创建目录36
      # 目录结构：../data/matches/2008-2009/36/1.htm
      unless File.directory?(File.expand_path("#{season}/", path))
        FileUtils.mkdir(File.expand_path("#{season}/", path))
      end
      unless File.directory?(File.expand_path("#{season}/#{match_id}/", path))
        FileUtils.mkdir(File.expand_path("#{season}/#{match_id}/", path))
      end
      schedule_file_path = File.expand_path("#{season}/#{match_id}/#{phase}.#{suffix}", path)
      return schedule_file_path
    end

    def schedule_data_file_exist?(season, match_id, phase, path, suffix)
      schedule_file_path = File.expand_path("#{season}/#{match_id}/#{phase}.#{suffix}", path)
      return schedule_file_path if File.exist?(schedule_file_path)
      return FALSE
    end

    def convert_special_bet007_id(bet007_match_id)
      bet007_match_id = bet007_match_id.to_i
      
      if bet007_match_id==37
        bet007_match_id = "37_87"
      end
      if bet007_match_id==40
        bet007_match_id = "40_261"
      end
      if bet007_match_id==9
        bet007_match_id = "9_132"
      end
      if bet007_match_id==16
        bet007_match_id = "16_98"
      end
      if bet007_match_id==5
        #bet007_match_id = "5_114"
      end
      return bet007_match_id
    end

    def convert_schedule_htm2csv(season, match_id, phase, path)
      schedule_htm_file = schedule_data_file(season, match_id, phase, path, 'htm')
      schedule_csv_file = schedule_data_file(season, match_id, phase, path, 'csv')
      return unless File.exist?(schedule_htm_file)
      return if File.exist?(schedule_csv_file)

      schedule = []

      schedule_html = File.read(schedule_htm_file)
      doc = Hpricot(schedule_html)
      count = 0
      schedule = doc.search("#Table3")
      matches = schedule/'tr'
      matches.each do |match|
        count+=1
        next if count<=2
        details = match/'td'
        break if details.size==1     # 不必导入下一轮赛事数据

        phase_id = (details[0]/'div')[0].inner_text
        return if phase_id.to_i != phase.to_i
        
        t_match_datetime = (details[1]/'div')[0].inner_html
        t_home = ((details[2]/'div')[0]/'a')[0].inner_html
        #match_goal =  details[3].inner_text
        t_away =  ((details[4]/'div')[0]/'a')[0].inner_html
        #rq_all = details[5].inner_text
        #dxq_all = details[7].inner_text
        #match_half_goal = details[10].inner_text

        home = t_home.split('<')[0]
        away = t_away.split('<')[0]

        t_match_date, t_match_time = t_match_datetime.split('<')
        match_time = t_match_time.split('>')[1]
        match_month = t_match_date.split('-')[0].to_i

        match_datetime = ''
        year1, year2 = season.split('-')
        if season.size > 4
          if match_month < 7
            match_datetime = "#{year2}-#{t_match_date} #{match_time}"
          else
            match_datetime = "#{year1}-#{t_match_date} #{match_time}"
          end
        else
          match_datetime = "#{year1}-#{t_match_date} #{match_time}"
        end

        schedule << "#{phase_id};#{match_datetime};#{home};;#{away};;;"
      end

      File.open(schedule_csv_file, "w") do |f|
        f.puts schedule.join("\n")
      end
    end

    # 输入的season只有一种格式，即2010
    # 2010-2011这种格式并非直接输入得到，而是根据match_id的类型计算而来
    def schedule_match_phase_loop(season, match_set)
      # 如果match_set为空，则取出所有需要统计的赛事
      if match_set.size == 0
        match_set = MatchHelper.match_need_stat.keys
      end

      # 依次处理每个赛事
      match_set.each do |match_id|
        # 获取当前赛事的赛季轮次
        phases = MatchHelper.get_phases(match_id)
        # 根据赛事ID重新计算season，因为输入的season都是2010格式，但是对于英超这样的赛事，season应该是2010-2011
        new_season = "#{season}-#{season.to_i+1}" if MatchHelper.match_schedule_two_year?(match_id)
        # 处理特殊赛事的phase数据
        bet007_match_id = convert_special_bet007_id(MatchHelper.get_bet007_match_id(match_id))

        # 依次处理每个轮次的数据
        1.upto(phases) do |phase_id|
          yield new_season, match_id, bet007_match_id, phase_id
        end
      end
    end

    # 根据赛季信息、赛事信息下载指定的数据
    def download_schedule_data(season, match_set, path)
      
      schedule_match_phase_loop(season, match_set) do |new_season, match_id, bet007_match_id, phase_id|
        # 如果当前轮次的数据已经存在，则不再下载
        continue if schedule_data_file_exist?(new_season, match_id, phase_id, path, 'htm')

        # 下载数据
        schedule_url = "http://info.bet007.com/league_match/league_vs/#{new_season}/#{bet007_match_id}_#{phase_id}.htm"

        begin
          # 代理服务器设置
          #schedule_data = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(schedule_url))
          schedule_data = Net::HTTP.get(URI.parse(schedule_url))
        rescue Exception=>ex
          $logger.error("#{path} download failed! #{ex}")
        end

        # 写入数据
        schedule_file_path = schedule_data_file(new_season, match_id, phase_id, path, 'htm')
        File.open(schedule_file_path, "w") do |f|
          f.puts schedule_data
        end

        # 将htm转换成csv
        convert_schedule_htm2csv(new_season, match_id, phase_id, path)
      end
    end

    def display_new_teams(teams)
      new_teams.each do |team|
        $logger.warning("#{team['team_name']}, #{MatchHelper.match_id_map[team['match_id']]['name']}, #{team['phase_id']}")
      end
    end

    def preprocess_team(season, match_set, path)
      new_teams = []
      schedule_match_phase_loop(season, match_set) do |new_season, match_id, bet007_match_id, phase_id|
        continue unless schedule_data_file_exist?(new_season, match_id, phase_id, path, 'csv')
        schedule_csv_path = schedule_data_file(new_season, match_id, phase_id, path, 'csv')
        File.open(schedule_csv_path, "r") do |f|
          until f.eof?
            match = f.readline
            details = match.split(';')
            
            team1_name = gbk2utf8(details[2])
            team2_name = gbk2utf8(details[4])

            unless TeamHelper.team_name_exist?(team1_name)
              new_teams << { "team_name" => team1_name, "match_id" => match_id, "phase_id" => phase_id }
            end
            unless TeamHelper.team_name_exist?(team2_name)
              new_teams << { "team_name" => team2_name, "match_id" => match_id, "phase_id" => phase_id }
            end
          end
        end
      end

      display_new_teams(new_teams)
    end

    # 读取csv文件中的赛程数据，导入数据库
    def insert_schedule(csv_file)
      schedule = []
      schedule_match_phase_loop(season, match_set) do |new_season, match_id, bet007_match_id, phase_id|
        continue unless schedule_data_file_exist?(new_season, match_id, phase_id, path, 'csv')
        schedule_csv_path = schedule_data_file(new_season, match_id, phase_id, path, 'csv')
        File.open(schedule_csv_path, "r") do |f|
          until f.eof?
            match = f.readline
            details = match.split(';')

            phase = details[0]
            match_datetime = details[1]
            team1_name = gbk2utf8(details[2])
            team2_name = gbk2utf8(details[4])

            team1_id = TeamHelper.get_team_id_by_name(team1_name)
            team2_id = TeamHelper.get_team_id_by_name(team2_name)

            exit if Schedule.schedule_exist?(new_season, match_id, phase_id, team1_id, team2_id)
            schedule << Schedule.new(
                                      :matchyear => new_season,
                                      :phase     => phase_id,
                                      :matchdt   => match_datetime,
                                      :matchno   => match_id,
                                      :team1no   => team1_id,
                                      :team2no   => team2_id
                                    )
          end
        end
      end

      Schedule.import(schedule)
    end
  end
end

