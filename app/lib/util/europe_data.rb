
require 'mysql/match'
require 'mysql/team'

require 'net/http'
require 'xml'
require 'iconv'

module Huuuunt
  module EuropeData
    def self.included(base)
      base.extend Huuuunt::EuropeData
    end

    def europe_data_file_exist?(date, path)
      return data_file_exist?(date, path, 'xml')
    end

    def download_europe_data(date, path)
      # 如果输入日期的赛果数据文件已经存在，则无需重复下载，直接返回
      return if europe_data_file_exist?(date, path)

      # bet007欧洲赔率数据URL
      europe_url = "http://vip.bet007.com/history/loadStandardXml.aspx?companyid=9,14,4,1,8,18,12,19,7,3,23,24,31,22,33,17,35&matchdate=#{date.to_s}&cmd=&hometeamID=&guestteamid=&kind=&odds1=&odds2=&odds3=&gsID=&sclassID=&searchTeam="

      begin
        puts europe_url
        # 代理服务器设置
        #europe_data = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(result_url))
        europe_data = Net::HTTP.get(URI.parse(europe_url))
      rescue Exception=>ex
        $logger.error("#{path} download failed! #{ex}")
        puts "#{path} download failed! #{ex}"
        return
      end

      $logger.debug("#{date} europe download finished!")

      # 计算数据文件保存路径
      europe_xml_file = data_file_path(date, path, 'xml')
      File.open(europe_xml_file, "w") do |f|
        f.puts europe_data
      end
    end

    # 处理赔率数据中的赛事名称
    # 1、如果简体名称和繁体名称在数据库中都不存在，则需要展示出来
    # 2、如果简体名称和繁体名称在数据库中都存在，则无需处理
    # 3、如果简体名称和繁体名称只有一个在数据库中存在，则将另一个插入到match_other_infos数据库表中
    def get_new_match(xml)
      # 返回的数据结构
      match_infos = []
      # 用于写入match_other_infos数据库表
      match_others = []
      
      read_europe_xml(xml) do |match_time, match_name_arr, match_color, home_arr, away_arr, goal, peilv|
        name_cn, name_tw, name_en = match_name_arr.split(',')

        # 判断name_cn和name_tw是否在数据库中已经存在?
        # 如果都不存在，则需要手工处理，否则，由程序自动处理

        # 手工处理部分
        if Match.match_name_exist?(name_cn) ||
            Match.match_name_exist?(name_tw)
          # name_cn和name_tw其中有一个在数据库中存在
          match_others << { "name_cn" => name_cn, "name_tw" => name_tw }
        else
          # name_cn和name_tw都不在数据库中存在
          match_infos << {
            "name_cn" => name_cn,
            "name_tw" => name_tw,
            "name_en" => name_en,
            "match_color" => match_color
          }
        end
      end

      # 写入match_other_infos数据库表中
      Match.select_insert_match_name(match_others)
      
      return match_infos
    end

    # 处理赔率数据中的球队名称
    # 1、如果简体名称和繁体名称在数据库中都不存在，则需要展示出来
    # 2、如果简体名称和繁体名称在数据库中都存在，则无需处理
    # 3、如果简体名称和繁体名称只有一个在数据库中存在，则将另一个插入到team_other_infos数据库表中
    def get_new_team(xml)
      # 用于返回的数据结构
      team_infos = []
      # 用于写入team_other_infos数据库表
      team_others = []
      read_europe_xml(xml) do |match_time, match_name_arr, match_color, home_arr, away_arr, goal, peilv|
        m_name_cn, m_name_tw, m_name_en = match_name_arr.split(",")
        h_name_cn, h_name_tw, h_name_en = home_arr.split(",")
        a_name_cn, a_name_tw, a_name_en = away_arr.split(",")

        #$logger.debug("#{m_name_cn} : #{h_name_cn}, #{h_name_tw}, #{h_name_en}, #{a_name_cn}, #{a_name_tw}, #{a_name_en}")

        # 判断该赛事是否要纳入统计(赛事名称无法识别的情况同样返回FALSE)
        unless Match.match_need_import?(m_name_cn)
          unless Match.match_need_import?(m_name_tw)
            next
          end
        end

        #$logger.debug("#{match_time}, #{m_name_cn}, #{m_name_tw}")

        # 判断球队的简体名称和繁体名称是否在数据库中已经存在?
        # 如果都不存在，则需要手工处理，否则，由程序自动处理

        # 手工处理
        if Team.team_name_exist?(h_name_cn) ||
            Team.team_name_exist?(h_name_tw)
          # 如果有一个能够识别，则把另外一个写入team_other_infos数据库表
          team_others << { "name_cn" => h_name_cn, "name_tw" => h_name_tw }
        else
          # 如果都不能识别
          team_infos << {
            "name_cn" => h_name_cn,
            "name_tw" => h_name_tw,
            "name_en" => h_name_en,
            "match_name" => m_name_cn
          }
        end

        if Team.team_name_exist?(a_name_cn) ||
            Team.team_name_exist?(a_name_tw)
          # 如果有一个能够识别，则把另外一个写入team_other_infos数据库表
          team_others << { "name_cn" => a_name_cn, "name_tw" => a_name_tw }
        else
          # 如果都不能识别
          team_infos << {
              "name_cn" => a_name_cn,
              "name_tw" => a_name_tw,
              "name_en" => a_name_en,
              "match_name" => m_name_cn
            }
        end
      end

      Team.select_insert_team_name(team_others)

      return team_infos
    end

    def read_europe_xml(xml)
      europe_xml = File.read(xml)
      xmlutf8 = Iconv.iconv("UTF-8", "GBK", europe_xml)
      parser = XML::Parser.string(xmlutf8[0], :encoding => XML::Encoding::UTF_8)
      doc = parser.parse
      doc.find("//m").each do |lang|
        match_color = lang.find_first('co').content # <co>#00A8A8</co>
        match_name_arr = lang.find_first('le').content # <le>友谊赛,友誼賽,INT CF</le>
        match_time = lang.find_first('t').content # <t>00:30</t>
        goal = lang.find_first('sc').content # <sc>-1,2,2</sc>  # -14:推迟，-12:腰斩
        home_arr = lang.find_first('ta').content # <ta>瓦克蒂罗尔,華卡迪路,FC Wacker Innsbruck</ta>
        away_arr = lang.find_first('tb').content # <tb>基辅迪纳摩,基輔戴拿模,Dynamo Kyiv</tb>
        peilv = lang.find_first('pl').content # <pl>,,,,,,;,,,,,,;,,,,,,;,,,,,,;,,,,,,;,,,,,,;877463,5.85,3.50,1.55,8.50,3.90,1.40;,,,,,,;,,,,,,;877439,5.05,3.50,1.50,6.70,3.50,1.40;877458,5.50,3.60,1.55,7.50,3.80,1.42;877469,5.25,3.45,1.50,6.00,3.45,1.40;,,,,,,;,,,,,,;,,,,,,;,,,,,,;,,,,,,</pl>
        
        yield match_time, match_name_arr, match_color, home_arr, away_arr, goal, peilv
      end
    end

    def display_new_match(match_infos)
      $logger.warn("新的赛事名称信息：")
      match_infos.each do |match|
        $logger.warn("#{match['name_cn']}, #{match['name_tw']}, #{match['name_en']}")
      end
    end

    def display_new_team(team_infos)
      $logger.warn("新的球队名称信息：")
      team_infos.each do |team|
        $logger.warn("#{team['name_cn']}, #{team['name_tw']}, #{team['name_en']}, (#{team['match_name']})")
      end
    end

    # 验证赛事名称和球队名称是否已经在数据库中存在，否则批量插入新的赛事名称和球队名称
    # 返回插入新数据的个数
    def preprocess_match_team(xml)
      # 验证赛事名称是否已经在数据库中存在，获取新的赛事名称
      match_infos = get_new_match(xml)

      if match_infos.size > 0
        display_new_match(match_infos)
        return match_infos.size
      end

      # 验证球队名称是否已经在数据库中存在，获取新的球队名称
      team_infos = get_new_team(xml)

      # 因为赛果数据已经导入，因此所有的的赛事名称和球队名称必然已经存在
      # 新的赛事名称和新的球队名称需要全部显示出来，用于判断处理
      if team_infos.size > 0
        display_new_team(team_infos)
      end

      return team_infos.size
    end
    
    # 验证所有待插入的赔率数据是否在赛果数据中已经存在，不存在则表示数据出错
    def all_europe_in_result?(date, xml)
      exist = TRUE
      read_europe_xml(xml) do |match_time, match_name_arr, match_color, home_arr, away_arr, goal, peilv|
        name_cn, name_tn, name_en = match_name_arr.split(",")
        home_cn, home_tn, home_en = home_arr.split(",")
        away_cn, away_tn, away_en = away_arr.split(",")
        
        status, goal1, goal2 = goal.split(",")
        status = status.to_i

        # 判断赛事是否需要纳入统计
        next unless Match.match_need_import?(name_cn)

        # 如果赛事未结束，则不处理
        next if status==-12 || status==-14
        
        match_datetime = "#{date.to_s} #{match_time}"
        match_id = Match.get_match_id_by_name(name_cn)
        home_team_id = Team.get_team_id_by_name(home_cn)
        away_team_id = Team.get_team_id_by_name(away_cn)

        matchinfono = create_matchinfono(date.to_s, match_id, home_team_id, away_team_id)

        unless Result.match_exist?(matchinfono)
          exist = FALSE
          $logger.warning("#{match_datetime} #{name_cn} #{home_cn} #{away_cn} #{goal1}:#{goal2} #{matchinfono} does not exist!")
        end
      end
      return exist
    end

    def insert_europe_data(date, xml)
      # 初始化存放待插入各欧洲赔率数据库表的Array
      europe_data = {}
      Europe.companies.each do |company|
        europe_data[company] = []
      end

      read_europe_xml(xml) do |match_time, match_name_arr, match_color, home_arr, away_arr, goal, peilv|
        name_cn, name_tn, name_en = match_name_arr.split(",")
        home_cn, home_tn, home_en = home_arr.split(",")
        away_cn, away_tn, away_en = away_arr.split(",")

        status, goal1, goal2 = goal.split(',')
        status = status.to_i
        result = goal1.to_i - goal2.to_i
   
        peilv_arr = peilv.split(';')

        # 判断赛事是否需要纳入统计
        next unless Match.match_need_import?(name_cn)

        # 如果赛事未结束，则不处理
        next if status==-12 || status==-14

        match_date = date.to_s
        match_id = Match.get_match_id_by_name(name_cn)
        home_id = Team.get_team_id_by_name(home_cn)
        away_id = Team.get_team_id_by_name(away_cn)

        matchinfono = create_matchinfono(date.to_s, match_id, home_id, away_id)

        Europe.companies.each_with_index do |company, index|
          if peilv_arr[index]
            next unless /[\d]/.match(peilv_arr[index])
            
            peilv =  peilv_arr[index].split(",")
            changeid = peilv[0]
            peilv.collect! { |item| (item.to_f*1000).to_i }
            
            company_class_name = company.singularize.titleize.split.join            
            
            src = <<-END_SRC
              europe_data[#{company}] << #{company_class_name}.new(
                                      :matchinfono => matchinfono,
                                      :matchdt => match_date,
                                      :matchno => match_id,
                                      :team1no => home_id,
                                      :team2no => away_id,
                                      :initwin => peilv[1],
                                      :initdeuce => peilv[2],
                                      :initloss => peilv[3],
                                      :finwin => peilv[4],
                                      :findeuce => peilv[5],
                                      :finloss => peilv[6],
                                      :result => result,
                                      :goal1 => goal1,
                                      :goal2 => goal2,
                                      :changeid => changeid,
                                      :home => home_cn,
                                      :away => away_cn )
            END_SRC

            eval src
          end
        end
      end
      
      # 执行插入各欧洲赔率数据库表的动作
      Europe.companies.each do |company|
        company_class_name = company.singularize.titleize.split.join
        src = <<-END_SRC
          #{company_class_name}.import(europe_data[#{company}])
        END_SRC
        
        eval src
      end
    end
  end
end
