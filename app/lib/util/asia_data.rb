
require 'mysql/match'
require 'mysql/team'

require 'net/http'
require 'xml'
require 'iconv'

module Huuuunt
  module AsiaData
    def self.included(base)
      base.extend Huuuunt::AsiaData
    end

    def asia_data_file_exist?(date, path)
      return data_file_exist?(date, path, 'xml')
    end

    def download_asia_data(date, path)
      # 如果输入日期的赛果数据文件已经存在，则无需重复下载，直接返回
      return if asia_data_file_exist?(date, path)

      # bet007亚洲赔率数据URL
      asia_url = "http://vip.bet007.com/history/loadAsianXml.aspx?companyid=3,23,24,31,33,1,8,4,14,12,22,17,35&matchdate=#{date.to_s}&cmd=&id1=&id2=&goal=&teamID=&gsID=&sclassID="

      begin
        # 代理服务器设置
        #asia_data = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(asia_url))
        asia_data = Net::HTTP.get(URI.parse(asia_url))
      rescue Exception=>ex
        $logger.error("#{path} download failed! #{ex}")
        puts "#{path} download failed! #{ex}"
        return
      end

      $logger.debug("#{date} europe download finished!")

      # 计算数据文件保存路径
      asia_xml_file = data_file_path(date, path, 'xml')
      File.open(asia_xml_file, "w") do |f|
        f.puts asia_data
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

      read_asia_xml(xml) do |match_time, match_name_arr, match_color, home_arr, away_arr, goal, direction, peilv|
        name_cn, name_tw, name_en = match_name_arr.split(',')

        # 判断name_cn和name_tw是否在数据库中已经存在?
        # 如果都不存在，则需要手工处理，否则，由程序自动处理

        # 手工处理部分
        if MatchHelper.match_name_exist?(name_cn) ||
            MatchHelper.match_name_exist?(name_tw)
          match_others << { :name_cn => name_cn, :name_tw => name_tw }
        else
          match_infos << {
            "name_cn" => name_cn,
            "name_tc" => name_tw,
            "name_en" => name_en,
            "match_color" => match_color
          }
        end
      end

      # 写入match_other_infos数据库表中
      MatchHelper.select_insert_match_name(match_others)

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
      read_europe_xml(xml) do |match_time, match_name_arr, match_color, home_arr, away_arr, goal, direction, peilv|
        m_name_cn, m_name_tw, m_name_en = match_name_arr.split(",")
        h_name_cn, h_name_tw, h_name_en = home_arr.split(",")
        a_name_cn, a_name_tw, a_name_en = away_arr.split(",")

        # 判断该赛事是否要纳入统计(赛事名称无法识别的情况同样返回FALSE)
        unless MatchHelper.match_need_import?(m_name_cn)
          unless MatchHelper.match_need_import?(m_name_tw)
            next
          end
        end

        # 判断球队的简体名称和繁体名称是否在数据库中已经存在?
        # 如果都不存在，则需要手工处理，否则，由程序自动处理

        # 手工处理
        if TeamHelper.team_name_exist?(h_name_cn) ||
            TeamHelper.team_name_exist?(h_name_tw)
          # 如果有一个能够识别，则把另外一个写入team_other_infos数据库表
          team_others << { :name_cn => h_name_cn, :name_tc => h_name_tw }
        else
          # 如果都不能识别
          team_infos << {
            :name_cn => h_name_cn,
            :name_tc => h_name_tw,
            :name_en => h_name_en,
            :match_name => m_name_cn
          }
        end

        if TeamHelper.team_name_exist?(a_name_cn) ||
            TeamHelper.team_name_exist?(a_name_tw)
          # 如果有一个能够识别，则把另外一个写入team_other_infos数据库表
          team_others << { :name_cn => a_name_cn, :name_tc => a_name_tw }
        else
          # 如果都不能识别
          team_infos << {
              :name_cn => a_name_cn,
              :name_tc => a_name_tw,
              :name_en => a_name_en,
              :match_name => m_name_cn
            }
        end
      end

      TeamHelper.select_insert_team_name(team_others)

      return team_infos
    end

    def read_asia_xml(xml)
      asia_xml = File.read(xml)
      xmlutf8 = Iconv.iconv("UTF-8", "GBK", asia_xml)
      parser = XML::Parser.string(xmlutf8[0], :encoding => XML::Encoding::UTF_8)
      doc = parser.parse
      doc.find("//m").each do |lang|
        match_color = lang.find_first('co').content # <co>#00A8A8</co>
        match_name_arr = lang.find_first('le').content.split(",") # <le>友谊赛,友誼賽,INT CF</le>
        match_time = lang.find_first('t').content # <t>00:30</t>
        goal = lang.find_first('sc').content.split(",") # <sc>-1,2,2,1,1</sc>  # -12:腰斩, -14:推迟
        home_arr = lang.find_first('ta').content.split(",") # <ta>瓦克蒂罗尔,華卡迪路,FC Wacker Innsbruck</ta>
        away_arr = lang.find_first('tb').content.split(",") # <tb>基辅迪纳摩,基輔戴拿模,Dynamo Kyiv</tb>
        direction = lang.find_first('p').content # <p>2</p>  1: 主让客, 2: 客让主
        peilv = lang.find_first('pl').content # <pl>789207,1,0.25,1.02,0.86,True;789233,1,0.25,1.111,0.80,True;789250,1,0.25,1.23,0.65,True;,,,,,;,,,,,;,,,,,;789252,1,1,0.70,1.10,False;,,,,,;,,,,,;789244,1,1,0.74,1.16,False;,,,,,;789239,1,1,0.72,1.25,False;,,,,,</pl>

        yield match_time, match_name_arr, match_color, home_arr, away_arr, goal, direction, peilv
      end
    end

    def display_new_match_team(match_infos, team_infos)
      match_infos.each do |match|
        $logger.warning("新的赛事名称信息：")
        $logger.warning("#{match['name_cn']}, #{match['name_tc']}, #{match['name_en']}")
      end

      team_infos.each do |team|
        $logger.warning("新的球队名称信息：")
        $logger.warning("#{team['name_cn']}, #{team['name_tc']}, #{team['name_en']}, #{team['match_name']}")
      end
    end

    # 验证赛事名称和球队名称是否已经在数据库中存在，否则批量插入新的赛事名称和球队名称
    # 返回插入新数据的个数
    def preprocess_match_team(xml)
      # 验证赛事名称是否已经在数据库中存在，获取新的赛事名称
      match_infos = get_new_match(xml)

      # 验证球队名称是否已经在数据库中存在，获取新的球队名称
      team_infos = get_new_team(xml)

      # 因为赛果数据已经导入，因此所有的的赛事名称和球队名称必然已经存在
      # 新的赛事名称和新的球队名称需要全部显示出来，用于判断处理
      display_new_match_team(match_infos, team_infos)

      return match_infos.size+team_infos.size
    end

    # 验证所有待插入的赔率数据是否在赛果数据中已经存在，不存在则表示数据出错
    def all_asia_in_result?(date, xml)
      exist = TRUE
      read_europe_xml(xml) do |match_time, match_name_arr, match_color, home_arr, away_arr, goal, direction, peilv|
        name_cn, name_tn, name_en = match_name_arr.split(",")
        home_cn, home_tn, home_en = home_arr.split(",")
        away_cn, away_tn, away_en = away_arr.split(",")

        status, goal1, goal2 = goal.split(",")
        status = status.to_i

        # 判断赛事是否需要纳入统计
        next unless MatchHelper.match_need_import?(name_cn)

        # 如果赛事未结束，则不处理
        next if status==-12 || status==-14

        match_datetime = "#{date.to_s} #{match_time}"
        match_id = MatchHelper.get_match_id_by_name(name_cn)
        home_team_id = TeamHelper.get_team_id_by_name(home_cn)
        away_team_id = TeamHelper.get_team_id_by_name(away_cn)

        matchinfono = create_matchinfono(date.to_s, match_id, home_team_id, away_team_id)

        unless Result.match_exist?(matchinfono)
          exist = FALSE
          $logger.warning("#{match_datetime} #{name_cn} #{home_cn} #{away_cn} #{goal1}:#{goal2} #{matchinfono} does not exist!")
        end
      end
      return exist
    end

    def insert_asia_data(date, xml)
      # 初始化存放待插入各赔率数据库表的Array
      asia_data = {}
      Asia.companies.each do |company|
        asia_data[company] = []
      end

      read_asia_xml(xml) do |match_time, match_name_arr, match_color, home_arr, away_arr, goal, direction, peilv|
        name_cn, name_tn, name_en = match_name_arr.split(",")
        home_cn, home_tn, home_en = home_arr.split(",")
        away_cn, away_tn, away_en = away_arr.split(",")

        status, goal1, goal2, halfgoal1, halfgoal2 = goal.split(',')
        status = status.to_i
        
        direction = case direction.to_i
                    when 1: 1
                    when 2: -1
                    else

                    end

        peilv_arr = peilv.split(';')

        # 判断赛事是否需要纳入统计
        next unless MatchHelper.match_need_import?(name_cn)

        # 如果赛事未结束，则不处理
        next if status==-12 || status==-14

        match_date = date.to_s
        match_id = MatchHelper.get_match_id_by_name(name_cn)
        home_id = TeamHelper.get_team_id_by_name(home_cn)
        away_id = TeamHelper.get_team_id_by_name(away_cn)

        matchinfono = create_matchinfono(date.to_s, match_id, home_id, away_id)

        Asia.companies.each_with_index do |company, index|
          if peilv_arr[index]
            next unless /[\d]/.match(peilv_arr[index])

            peilv =  peilv_arr[index].split(",")
            #changeid = peilv[0]
            peilv[1] = (peilv[1]*4).to_i
            peilv[2] = (peilv[2]*4).to_i
            peilv[3] = (peilv[3]*1000).to_i
            peilv[4] = (peilv[4]*1000).to_i

            result = calc_asia_result(peilv[2], direction, goal1, goal2)

            company_class_name = company.singularize.titleize.split.join

            src = <<-END_SRC
              asia_data[#{company}] << #{company_class_name}.new(
                                      :matchinfono => matchinfono,
                                      :matchdt => match_date,
                                      :matchno => match_id,
                                      :team1no => home_id,
                                      :team2no => away_id,
                                      :initrate => peilv[1],
                                      :finrate => peilv[2],
                                      :uplevel => peilv[3],
                                      :downlevel => peilv[4],
                                      :result => result,
                                      :halfgoal1 => halfgoal1,
                                      :halfgoal2 => halfgoal2,
                                      :goal1 => goal1,
                                      :goal2 => goal2,
                                      :direction => direction )
            END_SRC

            eval src
          end
        end
      end

      # 执行插入各赔率数据库表的动作
      Asia.companies.each do |company|
        company_class_name = company.singularize.titleize.split.join
        src = <<-END_SRC
          #{company_class_name}.import(asia_data[#{company}])
        END_SRC

        eval src
      end
    end
  end
end
