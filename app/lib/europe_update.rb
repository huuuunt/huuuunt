require 'rubygems'
require 'open-uri'
require 'net/http'
require 'iconv'
require 'date'
require 'xml'

class EuropeUpdate
  EUROPEPATH = "../data/europe/"

  @@europe_company = []
  
  @@data_from_xml = []
  @@multi_match_name = []
  @@multi_team_name = []

  def initialize(company_tables)
    @mysql = MysqlAccess.new()
    @@europe_company = company_tables
    @@europe_company.each do |company|
      #puts company
      @mysql.create_europe_bet_table_if_not_exist(company)
    end
    @mysql.init_stat_teams
  end

  def close
    @mysql.close
  end

  def get_standard_xml(date)
    begin
      europe_url = "http://vip.bet007.com/history/loadStandardXml.aspx?companyid=9,14,4,1,8,18,12,19,7,3,23,24,31,22,33,17,35&matchdate=#{date}&cmd=&hometeamID=&guestteamid=&kind=&odds1=&odds2=&odds3=&gsID=&sclassID=&searchTeam="
      #europe_xml = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(europe_url))
      europe_xml = Net::HTTP.get(URI.parse(europe_url))

      year, month, day = date.split('-')
      unless File.directory?(File.expand_path("#{year}/", EUROPEPATH))
        FileUtils.mkdir(File.expand_path("#{year}/", EUROPEPATH))
      end
      unless File.directory?(File.expand_path("#{year}/#{month.to_i}/", EUROPEPATH))
        FileUtils.mkdir(File.expand_path("#{year}/#{month.to_i}/", EUROPEPATH))
      end

      europe_file_path = File.expand_path("#{year}/#{month.to_i}/#{date}.xml", EUROPEPATH)
      #puts "#{europe_file_path}"
      File.open(europe_file_path, "w") do |f|
        f.puts europe_xml
      end
    rescue Exception=>ex
      puts ex
    end
  end

  def get_end_date
    # 默认每天0点后可以更新昨日的欧洲赔率数据
    now = Time.now
    yesterday = now - 60*60*24
    return "#{yesterday.year}-#{yesterday.month}-#{yesterday.day}"
  end

  # 把需要（纳入统计的赛事）和（未知的赛事）的比赛结果导入内存中
  def europe_analyse(filepath, date_start)
    europe_xml = File.read(filepath)
    xmlutf8 = Iconv.iconv("UTF-8", "GBK", europe_xml)
    parser = XML::Parser.string(xmlutf8[0], :encoding => XML::Encoding::UTF_8)
    doc = parser.parse
    doc.find("//m").each do |lang|
      match_color = lang.find_first('co').content # <co>#00A8A8</co>
      name_arr = lang.find_first('le').content # <le>友谊赛,友誼賽,INT CF</le>
      match_time = lang.find_first('t').content # <t>00:30</t>
      goal = lang.find_first('sc').content # <sc>-1,2,2</sc>  # -14:推迟，-12:腰斩
      home_arr = lang.find_first('ta').content # <ta>瓦克蒂罗尔,華卡迪路,FC Wacker Innsbruck</ta>
      away_arr = lang.find_first('tb').content # <tb>基辅迪纳摩,基輔戴拿模,Dynamo Kyiv</tb>
      peilv = lang.find_first('pl').content # <pl>,,,,,,;,,,,,,;,,,,,,;,,,,,,;,,,,,,;,,,,,,;877463,5.85,3.50,1.55,8.50,3.90,1.40;,,,,,,;,,,,,,;877439,5.05,3.50,1.50,6.70,3.50,1.40;877458,5.50,3.60,1.55,7.50,3.80,1.42;877469,5.25,3.45,1.50,6.00,3.45,1.40;,,,,,,;,,,,,,;,,,,,,;,,,,,,;,,,,,,</pl>
      #puts "#{match_color},#{name_arr},#{match_time},#{goal},#{home_arr},#{away_arr},#{peilv}"

      name_cn, name_tn, name_en = name_arr.split(",")
      home_cn, home_tn, home_en = home_arr.split(",")
      away_cn, away_tn, away_en = away_arr.split(",")

      goal0, goal1, goal2 = goal.split(',')
      status = goal0.to_i
      goal0 = goal1.to_i - goal2.to_i

      peilv_arr = peilv.split(';')

      if @mysql.is_match_stat(name_cn) == 0
        #puts "#{Iconv.iconv("GBK", "UTF-8", name_cn)} not need to stat"
      else
      # 导入已知赛事名称并且需要统计的数据和未知赛事名称的数据
        #puts "#{Iconv.iconv("GBK", "UTF-8", name_cn)} need to stat"
        @@data_from_xml.push({:match_color => match_color, :name=>name_cn, :status => status,
                              :match_date => date_start.to_s + " " + match_time + ":00", :result=>goal0,
                              :goal1=>goal1, :goal2=>goal2, :home=>home_cn, :away=>away_cn,
                              :home_tn=>home_tn, :away_tn=>away_tn, :peilv=>peilv})
        # 保存赛事名称和球队名称的简体中文、繁体中文和英文名称
        @@multi_match_name.push({:name_cn => name_cn, :name_tn => name_tn,
                                 :name_en => name_en, :color => match_color})
        @@multi_team_name.push({:name_cn => home_cn, :name_tn => home_tn, :name_en => home_en})
        @@multi_team_name.push({:name_cn => away_cn, :name_tn => away_tn, :name_en => away_en})
      end

    end
  end
  
  def check_match_info
    @@data_from_xml.each do |data|
      if !@mysql.is_match_exist(data[:name]) && !@mysql.is_match_new_exist(data[:name])
        @mysql.add_new_match(data[:name], data[:match_color], data[:match_date]);
      end
    end
  end

  def check_team_info
    @@data_from_xml.each do |data|
      if @mysql.is_match_stat(data[:name]) != 1
        next
      end
      if !@mysql.is_team_exist(data[:home]) && !@mysql.is_team_new_exist(data[:home])
        @mysql.add_new_team(data[:name], data[:home], data[:match_date])
      end
      if !@mysql.is_team_exist(data[:away]) && !@mysql.is_team_new_exist(data[:away])
        @mysql.add_new_team(data[:name], data[:away], data[:match_date])
      end
    end
  end

  def all_europe_data_exist_in_results?(match_set)
    return @mysql.check_europe_data_exist_in_results(@@data_from_xml, match_set)
  end
  
  def do_real_update(match_set)
    @mysql.insert_europe_bet_data(@@data_from_xml, @@europe_company, match_set);
  end

  def check_match_and_team_info
    @@data_from_xml.each do |data|
      if !@mysql.is_match_exist(data[:name]) && !@mysql.is_match_new_exist(data[:name])
        @mysql.add_new_match(data[:name], data[:match_color]);
      end
      if !@mysql.is_team_exist(data[:home]) && !@mysql.is_team_new_exist(data[:home])
        @mysql.add_new_team(data[:name], data[:home])
      end
      if !@mysql.is_team_exist(data[:away]) && !@mysql.is_team_new_exist(data[:away])
        @mysql.add_new_team(data[:name], data[:away])
      end
    end
  end

  def do_update(match_set, start_date, end_date)
    # 获取数据库中最新的日期，从而确定开始更新欧洲赔率数据的起始日期
    start_date = @mysql.get_europe_latest_date    unless start_date
    #puts "start_date = #{start_date}"
    # 确定更新欧洲赔率数据的结束日期
    end_date = get_end_date   unless end_date
	start_date = '2011-02-08'
	end_date = '2012-09-08'
    
    puts "EUROPE: start_date = #{start_date}, end_date = #{end_date}"
    
    date_start = Date.parse(start_date)
    date_end = Date.parse(end_date)
    # 起始日期 -> 结束日期，循环处理
    while date_start <= date_end
      puts "Deal europe date is #{date_start}"

      # 查询本机指定目录是否存在该日期的赛果文件
      europe_file_path = File.expand_path("#{date_start.year}/#{date_start.month}/#{date_start.to_s}.xml", EUROPEPATH)
      puts "#{europe_file_path}, #{File.exist?(europe_file_path)}"
      unless File.exist?(europe_file_path)
        # 从网站获取原始数据，保存成文本文件
        get_standard_xml(date_start.to_s)
        puts "Get #{date_start.to_s} europe data from web!"
      end

      # 如果从web获取数据失败，或写入文件失败，则退出
      break unless File.exist?(europe_file_path)

      # 读取赛果文本文件，分析处理
      europe_analyse(europe_file_path, date_start)

      # 准备处理下一个日期的数据
      date_start = date_start.succ

      #break
    end
	
	# 2012-09-09 临时加入
	exit
	
    # 以上日期数据文件的处理，将所有读取文件中的已经纳入统计的赛事和未知赛事的比赛结果导入内存中
    
    @mysql.init_multi_match_name
    @mysql.deal_multi_match_name(@@multi_match_name)
    @mysql.init_multi_team_name
    @mysql.deal_multi_team_name(@@multi_team_name)

    # 因为赛事结果数据已经导入，赛事名称和主客场球队名称都必然已经存在，
    # 因此不能再将数据库中不存在的赛事名称和球队名称直接插入数据库
    # 而是要将不存在的名称显示出来，手工进行添加
    @mysql.init_match_map
    @mysql.init_team_map
    check_match_info
    @mysql.display_new_match_info();
    if @mysql.should_stop_update
      puts "update stop,please check the match name display above"
      exit
    end
    check_team_info
    @mysql.display_new_team_info();
    if @mysql.should_stop_update
      puts "update stop,please check the team name display above"
      exit
    end

    # 以上动作保证了内存中的所有赛事数据的赛事名称和球队名称都能被识别

    # 确保要导入的欧洲赔率数据在赛果数据中都已经存在
    if !all_europe_data_exist_in_results?(match_set)
      puts "Some europe data not exist in result!"
      return
    end

    puts "Europe data has been checked in results!"
    
    do_real_update(match_set)
  end
end
