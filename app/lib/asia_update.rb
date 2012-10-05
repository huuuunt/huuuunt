require 'rubygems'
require 'open-uri'
require 'net/http'
require 'iconv'
require 'date'
require 'xml'

class AsiaUpdate
  ASIAPATH = "../data/asia/"

  @@asia_company = []
  
  @@data_from_xml = []
  @@multi_match_name = []
  @@multi_team_name = []

  def initialize(company_tables)
    @mysql = MysqlAccess.new()
    @@asia_company = company_tables
    @@asia_company.each do |company|
      @mysql.create_bet_table_if_not_exist(company)
    end
  end

  def close
    @mysql.close
  end

  def get_standard_xml(date)
    begin
      asia_url = "http://vip.bet007.com/history/loadAsianXml.aspx?companyid=3,23,24,31,33,1,8,4,14,12,22,17,35&matchdate=#{date}&cmd=&id1=&id2=&goal=&teamID=&gsID=&sclassID="
      #asia_xml = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(asia_url))
      asia_xml = Net::HTTP.get(URI.parse(asia_url))

      year, month, day = date.split('-')
      unless File.directory?(File.expand_path("#{year}/", ASIAPATH))
        FileUtils.mkdir(File.expand_path("#{year}/", ASIAPATH))
      end
      unless File.directory?(File.expand_path("#{year}/#{month.to_i}/", ASIAPATH))
        FileUtils.mkdir(File.expand_path("#{year}/#{month.to_i}/", ASIAPATH))
      end

      asia_file_path = File.expand_path("#{year}/#{month.to_i}/#{date}.xml", ASIAPATH)
      #puts "#{asia_file_path}"
      File.open(asia_file_path, "w") do |f|
        f.puts asia_xml
      end
    rescue Exception=>ex
      puts ex
    end
  end

  def get_end_date
    # 默认每天0点后可以更新昨日的亚洲赔率数据
    now = Time.now
    yesterday = now - 60*60*24
    return "#{yesterday.year}-#{yesterday.month}-#{yesterday.day}"
  end

  def asia_analyse(filepath, date_start)
    asia_xml = File.read(filepath)
    xmlutf8 = Iconv.iconv("UTF-8", "GBK", asia_xml)
    parser = XML::Parser.string(xmlutf8[0], :encoding => XML::Encoding::UTF_8)
    doc = parser.parse
    doc.find("//m").each do |lang|
      match_color = lang.find_first('co').content # <co>#00A8A8</co>
      name_arr = lang.find_first('le').content.split(",") # <le>友谊赛,友誼賽,INT CF</le>
      match_time = lang.find_first('t').content # <t>00:30</t>
      goal = lang.find_first('sc').content.split(",") # <sc>-1,2,2,1,1</sc>  # -12:腰斩, -14:推迟
      home_arr = lang.find_first('ta').content.split(",") # <ta>瓦克蒂罗尔,華卡迪路,FC Wacker Innsbruck</ta>
      away_arr = lang.find_first('tb').content.split(",") # <tb>基辅迪纳摩,基輔戴拿模,Dynamo Kyiv</tb>
      direction = lang.find_first('p').content # <p>2</p>  1: 主让客, 2: 客让主
      peilv = lang.find_first('pl').content # <pl>789207,1,0.25,1.02,0.86,True;789233,1,0.25,1.111,0.80,True;789250,1,0.25,1.23,0.65,True;,,,,,;,,,,,;,,,,,;789252,1,1,0.70,1.10,False;,,,,,;,,,,,;789244,1,1,0.74,1.16,False;,,,,,;789239,1,1,0.72,1.25,False;,,,,,</pl>
      #puts "#{match_color},#{name_arr},#{match_time},#{goal},#{home_arr},#{away_arr},#{direction},#{peilv}"

      if @mysql.is_match_stat(name_arr[0]) == 0
        #puts "#{Iconv.iconv("GBK", "UTF-8", name_cn)} not need to stat"
      else
      # 导入已知赛事名称并且需要统计的数据和未知赛事名称的数据
        @@data_from_xml.push({:match_color => match_color, :name=>name_arr[0], :status=>goal[0].to_i,
                            :match_date => date_start.to_s + " " + match_time + ":00", 
                            :goal1=>goal[1].to_i, :goal2=>goal[2].to_i,
                            :halfgoal1=>goal[3].to_i, :halfgoal2=>goal[4].to_i,
                            :home=>home_arr[0], :away=>away_arr[0], :direction=>direction.to_i,
                            :peilv=>peilv, :match_date_s => date_start.to_s})
        # 保存赛事名称和球队名称的简体中文、繁体中文和英文名称
        @@multi_match_name.push({:name_cn => name_arr[0], :name_tn => name_arr[1],
                                 :name_en => name_arr[2], :color => match_color})
        @@multi_team_name.push({:name_cn => home_arr[0], :name_tn => home_arr[1], :name_en => home_arr[2]})
        @@multi_team_name.push({:name_cn => away_arr[0], :name_tn => away_arr[1], :name_en => away_arr[2]})
      end
    end
  end
  
  def do_real_update(match_set)
    @mysql.insert_asia_bet_data(@@data_from_xml, @@asia_company, match_set);
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

  def check_match_and_team_info
    @@data_from_xml.each do |data|
      if !@mysql.is_match_exist(data[:name]) && !@mysql.is_match_new_exist(data[:name])
        @mysql.add_new_match(data[:name], data[:match_color], data[:match_date]);
      end
      if !@mysql.is_team_exist(data[:home]) && !@mysql.is_team_new_exist(data[:home])
        @mysql.add_new_team(data[:name], data[:home], data[:match_date])
      end
      if !@mysql.is_team_exist(data[:away]) && !@mysql.is_team_new_exist(data[:away])
        @mysql.add_new_team(data[:name], data[:away], data[:match_date])
      end
    end
  end

  def do_update(match_set, start_date, end_date)
    # 获取数据库中最新的日期，从而确定开始更新亚洲赔率数据的起始日期    
    start_date = @mysql.get_asia_latest_date    unless start_date
    #puts "start_date = #{start_date}"
    # 确定更新亚洲赔率数据的结束日期
    end_date = get_end_date   unless end_date
	start_date = '2011-02-08'
	end_date = '2012-09-08'
    
    puts "ASIA: start_date = #{start_date}, end_date = #{end_date}"
    
    date_start = Date.parse(start_date)
    date_end = Date.parse(end_date)
    # 起始日期 -> 结束日期，循环处理
    while date_start <= date_end
      puts "Deal asia date is #{date_start}"

      # 查询本机指定目录是否存在该日期的赛果文件
      asia_file_path = File.expand_path("#{date_start.year}/#{date_start.month}/#{date_start.to_s}.xml", ASIAPATH)
      puts "#{asia_file_path}, #{File.exist?(asia_file_path)}"
      unless File.exist?(asia_file_path)
        # 从网站获取原始数据，保存成文本文件
        get_standard_xml(date_start.to_s)
        puts "Get #{date_start.to_s} asia data from web!"
      end

      # 如果从web获取数据失败，或写入文件失败，则退出
      break unless File.exist?(asia_file_path)

      # 读取赛果文本文件，分析处理
      #asia_analyse(asia_file_path, date_start)

      # 准备处理下一个日期的数据
      date_start = date_start.succ

      #break
    end
	
	# 2012-09-09 临时加入
	exit
	
	# 以上日期数据文件的处理，将所有读取文件中的已经纳入统计的赛事和未知赛事的比赛结果导入内存中
    
    # 先处理赛事名称和球队名称的简体中文、繁体中文和英文的导入
    # 导入数据库中可以找到的赛事名称和球队名称，
    # 不能找到的留给check_match_and_team_info检查显示后手工处理
    # 如果有数据导入，则要重新加载@@orginal_match_map和@@orginal_team_map数据，便于后续处理
    @mysql.init_multi_match_name
    @mysql.deal_multi_match_name(@@multi_match_name)
    @mysql.init_multi_team_name
    @mysql.deal_multi_team_name(@@multi_team_name)

    # 因为赛事结果数据已经导入，赛事名称和主客场球队名称都必然已经存在，
    # 因此不能再将数据库中不存在的赛事名称和球队名称直接插入数据库
    # 而是要将不存在的名称显示出来，手工进行添加

    # 重新初始化match和team的数据
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

    # 导入指定联赛及其下属球队相关的所有赛事
    do_real_update(match_set)
  end
end
