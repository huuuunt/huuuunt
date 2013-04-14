# encoding: utf-8
require 'rubygems'
require 'hpricot'

require 'mysql/match'
require 'mysql/team'

module Huuuunt
  module ResultData
    def self.included(base)
      base.extend Huuuunt::ResultData
    end
    
    # 判断数据文件是否已经存在
    def result_data_file_exist?(date, path)
      data_file_exist?(date, path, 'html')
    end

    # 赛果数据中赛事名称预处理
    def preprocess_result_match_name(match_name)
      return match_name.strip
    end

    # 赛果数据中球队名称预处理
    def preprocess_result_team_name(team_name)
      team_name_utf8 = gbk2utf8(team_name)
        if team_name_utf8.index('(中)')
          team_name_utf8 =  team_name_utf8.sub(/\(中\)/, '')
        end
      team_name = utf82gbk(team_name_utf8)
      return team_name
    end

    # 将下载后的html文件转换成csv文件
    # 1、第一行数据是表头，无需读取
    # 2、注意处理无效数据行，如“先开球(小阿根廷人)”，判断依据：
    # 3、球队名称预处理：
    def result_html2csv(html_file, csv_file)
      # 读取html文件，并用Hpricot转换成document tree结构
      doc = Hpricot(File.read(html_file))

      results = []
      # 赛果数据存放在schedule结构中
      schedule = doc.search("#schedule")
      matches = schedule/'tr'
      matches.each_with_index do |match, index|
        # 第一行数据是表头，无需读取
        next if index==0
        details = match/'td'
        # 无效数据行，如“先开球(小阿根廷人)”
        next if details.size==1

        line = []
        details.each_with_index do |item, index|
          break if index==7
          data = item.inner_text
          # 需要预处理主客队的球队名称
          if index==3 or index==5
            data = preprocess_result_team_name(data)
          end
          line << data
        end        
        results << line.join(';')
      end

      File.open(csv_file, "w") do |f|
        f.puts results.join("\n")
      end
    end

    # 下载赛果数据，写入HTML文件,最后转换成CSV文件
    def download_result_data(date, path)
      # 如果输入日期的赛果数据文件已经存在，则无需重复下载，直接返回
      return if result_data_file_exist?(date, path)

      # bet007赛果数据URL
      result_url = "http://bf.bet007.com/Over_matchdate.aspx?matchdate=#{date.to_s}&team=&sclass="

      begin
        # 代理服务器设置
        #result_data = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(result_url))
        result_data = Net::HTTP.get(URI.parse(result_url))
      rescue Exception=>ex
        #$logger.error("#{path} download failed! #{ex}")
      end

      puts "Result #{date} download successfully!"

      #$logger.debug("Result #{date} data download successfully!!!")

      # 计算数据文件保存路径
      result_html_file = data_file_path(date, path, 'html')
      File.open(result_html_file, "w") do |f|
        f.puts result_data
      end

      # 将html文件转换成csv
      result_csv_file = data_file_path(date, path, 'csv')
      result_html2csv(result_html_file, result_csv_file)

      #$logger.debug("Result #{date} file convert to csv successfully!!!")
    end

    # 判断赛果数据中的赛事名称是否在数据库中已经存在
    # 如果赛事名称不存在，则统一记录到match_infos返回
    def get_new_match(csv)
      match_infos = []
      File.open(csv, "r") do |f|
        until f.eof?
          match = f.readline
          details = match.split(';')
          match_name = gbk2utf8(details[0])          # 美乙

          unless Match.match_name_exist?(match_name)
            match_infos << match_name
          end
        end
      end
      
      return match_infos
    end

    # 判断赛果数据中的球队名称是否在数据库中已经存在
    # 如果球队名称不存在，则统一记录到team_infos返回
    def get_new_team(csv)
      team_infos = []
      File.open(csv, "r") do |f|
        until f.eof?
          match = f.readline
          details = match.split(';')
          match_name = gbk2utf8(details[0])          # 美乙

          next unless Match.match_need_import?(match_name)
          
          match_id = Match.get_match_id_by_name(match_name)

          team1_name = gbk2utf8(details[3])
          team2_name = gbk2utf8(details[5])

          unless Team.team_name_exist?(team1_name)
            team_infos << { "team_name" => team1_name, "match_id" => match_id }
          end
          unless Team.team_name_exist?(team2_name)
            team_infos << { "team_name" => team2_name, "match_id" => match_id }
          end
        end
      end

      return team_infos
      return 
    end

    # 验证赛事名称和球队名称是否已经在数据库中存在，否则批量插入新的赛事名称和球队名称
    # 返回插入新数据的个数
    def preprocess_match_team(csv)
      # 验证赛事名称是否已经在数据库中存在，否则批量插入新的赛事名称
      match_infos = get_new_match(csv)
      Match.insert_new_match_name(match_infos)
      
      #return match_infos.size if match_infos.size > 0

      # 验证球队名称是否已经在数据库中存在，否则批量插入新的球队名称
      team_infos = get_new_team(csv)
      Team.insert_new_team_name(team_infos)

      return team_infos.size
    end

    # 读取csv文件中的赛事结果数据，导入数据库
    def insert_new_result(csv_file)
      results = []
      File.open(csv_file, "r") do |f|
        until f.eof?
          match = f.readline
          details = match.split(';')

          match_name = gbk2utf8(details[0])

          next unless Match.match_need_import?(match_name)

          team1_name = gbk2utf8(details[3])
          team2_name = gbk2utf8(details[5])
          match_datetime = details[1]      # 08-06-21 08:00
          match_status = details[2]        # 完
          match_goal =  details[4]         # 1-1
          match_half_goal = details[6].strip     # 0-0  # strip删除换行符\n

          # 获取赛事ID、主客队球队ID
          match_id = Match.get_match_id_by_name(match_name)
          team1_id = Team.get_team_id_by_name(team1_name)
          team2_id = Team.get_team_id_by_name(team2_name)
          # 计算半全场进球情况
          goal1,goal2 = match_goal.split('-')
          h_goal1,h_goal2 = match_half_goal.split('-')
          goal1 = gooooal(goal1)
          goal2 = gooooal(goal2)
          h_goal1 = gooooal(h_goal1)
          h_goal2 = gooooal(h_goal2)
          # 比赛状态：1:完, 2:推迟, 3:取消, 4:腰斩, 5:待定
          match_status = gbk2utf8(match_status)
          status =  case match_status
                    when "完" then 1
                    when "推迟" then 2
                    when "取消"then 3
                    when "腰斩"then 4
                    when "待定" then 5
                    else 6
                    end

          # 计算比赛日期
          match_dt = "20" + match_datetime
          match_date = (match_dt.split)[0]

          matchinfono = create_matchinfono(match_date, match_id, team1_id, team2_id)

          #puts "#{matchinfono},#{match_date},#{match_id},#{team1_id},#{team2_id},#{h_goal1},#{h_goal2},#{goal1},#{goal2},#{status}"

          # 判断该比赛结果是否已经存在数据库中，如果不存在，则保存到待插入的队列中
          unless Result.match_exist?(matchinfono)
            results << Result.new( :matchinfono => matchinfono,
                                   :matchdt => match_dt,
                                   :matchno=> match_id,
                                   :team1no => team1_id,
                                   :team2no => team2_id,
                                   :goal1 => goal1,
                                   :goal2 => goal2,
                                   :halfgoal1 => h_goal1,
                                   :halfgoal2 => h_goal2,
                                   :status => status
                       )
          else
            #$logger.warn("#{matchinfono} exist!!! --- #{match_dt}, #{Match.match_id_map[match_id]['name']}, #{Team.team_id_map[team1_id]['team_name']}, #{Team.team_id_map[team2_id]['team_name']}")
            puts "#{matchinfono} exist!!! --- #{match_dt}, #{Match.match_id_map[match_id]['name']}, #{Team.team_id_map[team1_id]['team_name']}, #{Team.team_id_map[team2_id]['team_name']}"
            return
          end
        end # until f.eof?
      end # File.open

      Result.import(results)
    end # insert_new_result
    
  end
end

