require 'rubygems'
require 'open-uri'
require 'net/http'
require 'iconv'
require 'date'
require 'hpricot'
require 'huuuunt_util'

class ResultUpdate
  RESULTPATH = "../data/result/"

  def initialize
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new
  end

  def close
    @mysql.close
  end

  # date format: 2009-09-09
  def get_standard_xml(date)
    begin
      result_url = "http://bf.bet007.com/Over_matchdate.aspx?matchdate=#{date}&team=&sclass="
      #result_xml = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(result_url))
      result_xml = Net::HTTP.get(URI.parse(result_url))
      #return result_xml

      year,month,day = date.split('-')
      unless File.directory?(File.expand_path("#{year}/", RESULTPATH))
        FileUtils.mkdir(File.expand_path("#{year}/", RESULTPATH))
      end
      unless File.directory?(File.expand_path("#{year}/#{month.to_i}/", RESULTPATH))
        FileUtils.mkdir(File.expand_path("#{year}/#{month.to_i}/", RESULTPATH))
      end
      result_file_path = File.expand_path("#{year}/#{month.to_i}/#{date}.html", RESULTPATH)
      #puts "#{result_file_path}"
      File.open(result_file_path, "w") do |f|
        f.puts result_xml
      end
    rescue Exception=>ex
      puts ex
    end
  end

  def get_end_date
    # 默认每天上午9点后可以更新昨日的赛果数据，而上午9点之前，只能更新前两天的赛果数据
    now = Time.now
    yesterday = now - 60*60*24
    yesterday2 = now - 2*60*60*24
    std_time = "#{now.year}-#{now.month}-#{now.day} 09:00:00"
    if now > Time.parse(std_time)
      return "#{yesterday.year}-#{yesterday.month}-#{yesterday.day}"
    else
      return "#{yesterday2.year}-#{yesterday2.month}-#{yesterday2.day}"
    end
  end

  def result_read(filepath)
    result_html = File.read(filepath)
    doc = Hpricot(result_html)
    count = 0
    schedule = doc.search("#schedule")
    matches = schedule/'tr'
    matches.each do |match|       
        count+=1
        next if count<=1          # 第一行数据是表头，无需读取
        details = match/'td'
        #puts "details.size = #{details.size}"
        next if details.size==1   # 无效数据行，如“先开球(小阿根廷人)”
      
        yield match
        
        #details = match/'td'
        #match_name = details[0].inner_text          # 美乙
        #match_datetime = details[1].inner_text      # 08-06-21 08:00
        #match_status = details[2].inner_text        # 完
        #match_home =  details[3].inner_text         # 查勒斯頓電池
        #match_goal =  details[4].inner_text         # 1-1
        #match_away = details[5].inner_text          # 明尼蘇達群星
        #match_half_goal = details[6].inner_text     # 0-0

        #puts "#{match_name},#{match_datetime},#{match_status},#{match_home},#{match_goal},#{match_away},#{match_half_goal}"
        
        #break if count>1
    end
  end

  def result_write_to_csv(result_html, result_csv)
    csv_handle = File.open(result_csv, "w")
    result_read(result_html) do |match|
      details = match/'td'
      match_name = details[0].inner_text          # 美乙
      match_datetime = details[1].inner_text      # 08-06-21 08:00
      match_status = details[2].inner_text        # 完
      match_home =  details[3].inner_text         # 查勒斯頓電池
      match_goal =  details[4].inner_text         # 1-1
      match_away = details[5].inner_text          # 明尼蘇達群星
      match_half_goal = details[6].inner_text     # 0-0

      match_home = @util.deal_result_team_name(match_home)
      match_away = @util.deal_result_team_name(match_away)

      csv_handle.puts "#{match_name};#{match_datetime};#{match_status};#{match_home};#{match_goal};#{match_away};#{match_half_goal}"
    end
    csv_handle.close
  end

  def result_csv_read(filepath)
    f = File.open(filepath, "r")
    until f.eof?
      yield f.readline
    end
    f.close
  end

  # 获取所有的赛事名称
  def result_new_match_exist?(filepath)
    new_match_exist = false
    result_csv_read(filepath) do |match|
      details = match.split(';')

      match_name_gbk = details[0]          # 美乙
      #puts "#{match_name_gbk}"
      match_name_utf8 = Iconv.iconv("UTF-8", "GBK", match_name_gbk)
      # 判断赛事名称是否存在数据库中
      unless @mysql.is_match_name_exist?(match_name_utf8)
        puts "match name(#{match_name_utf8}) has not exist! "
        # 如果有新赛事名称插入，则标识
        new_match_exist = true
        # 如果不存在，则插入数据库
        current_match_id = @mysql.get_max_match_id
        @mysql.insert_match_infos(current_match_id+1, match_name_utf8, '', '', '', '#000000', 0, 0, 0, 0, 0)
      end
    end
    @mysql.commit
    return new_match_exist
  end

  # 根据需要载入数据库的赛事数据，选择性地载入球队信息
  def result_new_team_exist?(filepath)
    new_team_exist = false
    result_csv_read(filepath) do |match|
      details = match.split(';')
      
      match_name_gbk = details[0]
      match_name_utf8 = Iconv.iconv("UTF-8", "GBK", match_name_gbk)[0]

      if !@mysql.is_match_need_stat?(match_name_utf8)
        #puts "#{match_name_gbk} doesn't need to be stat!"
        next
      end
      
      team1_name_gbk = details[3]
      team2_name_gbk = details[5]
      #puts "[#{match_name_gbk}], [#{team1_name_gbk}], [#{team2_name_gbk}]"
      
      team1_name_utf8 = Iconv.iconv("UTF-8", "GBK", team1_name_gbk)[0]
      team2_name_utf8 = Iconv.iconv("UTF-8", "GBK", team2_name_gbk)[0]

      # 获取赛事ID
      match_id = @mysql.get_match_id_by_match_name(match_name_utf8)
      if match_id==0
        puts "#{match_name_utf8} has no match id!"
        return true
      end
      # 判断主队名称
      unless @mysql.is_team_name_exist?(team1_name_utf8)
        puts "team name(#{team1_name_utf8}) has not exist! - match name(#{match_name_utf8})"
        new_team_exist = true
        current_team_id = @mysql.get_max_team_id
        @mysql.insert_team_infos(current_team_id+1, team1_name_utf8, match_id, '', '', '')
      end
      # 判断客队名称
      unless @mysql.is_team_name_exist?(team2_name_utf8)
        puts "team name(#{team2_name_utf8}) has not exist! - match name(#{match_name_utf8})"
        new_team_exist = true
        current_team_id = @mysql.get_max_team_id
        @mysql.insert_team_infos(current_team_id+1, team2_name_utf8, match_id, '', '', '')
      end
    end
    @mysql.commit
    return new_team_exist
  end

  def result_insert(filepath)
    result_csv_read(filepath) do |match|
      details = match.split(';')
      
      match_name_gbk = details[0]
      match_name_utf8 = Iconv.iconv("UTF-8", "GBK", match_name_gbk)[0]
      
      if !@mysql.is_match_need_stat?(match_name_utf8)
        #puts "#{match_name_gbk} doesn't need to be stat!"
        next
      end

      team1_name_gbk = details[3]
      team2_name_gbk = details[5]
      match_datetime = details[1]      # 08-06-21 08:00
      match_status = details[2]        # 完
      match_goal =  details[4]         # 1-1
      match_half_goal = details[6].strip     # 0-0  # strip删除换行符\n
      
      #puts "#{match_name_gbk}, #{team1_name_gbk}, #{team2_name_gbk}"
      team1_name_utf8 = Iconv.iconv("UTF-8", "GBK", team1_name_gbk)[0]
      team2_name_utf8 = Iconv.iconv("UTF-8", "GBK", team2_name_gbk)[0]
      
      # 获取赛事ID
      match_id = @mysql.get_match_id_by_match_name(match_name_utf8)
      team1_id = @mysql.get_team_id_by_team_name(team1_name_utf8)
      team2_id = @mysql.get_team_id_by_team_name(team2_name_utf8)
      goal1,goal2 = match_goal.split('-')
      h_goal1,h_goal2 = match_half_goal.split('-')
      status = 1  # 1:完, 2:推迟, 3:取消, 4:腰斩
      if Iconv.iconv("UTF-8", "GBK", match_status)[0] == "完"
        status = 1
      elsif Iconv.iconv("UTF-8", "GBK", match_status)[0] == "推迟"
        status = 2
      elsif Iconv.iconv("UTF-8", "GBK", match_status)[0] == "取消"
        status = 3
      elsif Iconv.iconv("UTF-8", "GBK", match_status)[0] == "腰斩"
        status = 4
      else # 其它赛事情况
        status = 5
      end
      match_dt = "20" + match_datetime
      match_date = (match_dt.split)[0]

      goal1 = goal1.strip if goal1!=nil
      goal2 = goal2.strip if goal2!=nil
      h_goal1 = h_goal1.strip if h_goal1!=nil
      h_goal2 = h_goal2.strip if h_goal2!=nil
      if goal1==nil || goal1.size==0
        goal1 = -1
      end
      if goal2==nil || goal2.size==0
        goal2 = -1
      end
      if h_goal1==nil || h_goal1.size==0
        h_goal1 = -1
      end
      if h_goal2==nil || h_goal2.size==0
        h_goal2 = -1
      end
      
      matchinfono = @util.create_matchinfono(match_date, match_id, team1_id, team2_id)
      #puts "#{matchinfono},#{match_date},#{match_id},#{team1_id},#{team2_id},#{h_goal1},#{h_goal2},#{goal1},#{goal2},#{status}"

      # 判断该比赛结果是否已经存在数据库中，如果不存在，则插入
      unless @mysql.is_match_exist?(matchinfono)
        puts "insert result #{matchinfono}"
        @mysql.insert_or_update_results(matchinfono, match_dt, match_id, team1_id, team2_id,
                              h_goal1, h_goal2, goal1, goal2, status)
      end
    end
    @mysql.commit
  end

  def result_analyse(filepath)
    if result_new_match_exist?(filepath)
      return false
    end
    if result_new_team_exist?(filepath)
      return false
    end
    result_insert(filepath)
    return true
  end
  
  def do_update(start_date, end_date)
    # 获取数据库中最新的日期，从而确定开始更新赛果的起始日期
    start_date = @mysql.get_result_latest_date    unless start_date
    #puts "start_date = #{start_date}"
    # 确定更新赛果的结束日期
    end_date = get_end_date   unless end_date
	    
    puts "RESULT: start_date = #{start_date}, end_date = #{end_date}"

    date_start = Date.parse(start_date)
    date_end = Date.parse(end_date)

    # 起始日期 -> 结束日期，循环处理
    while date_start <= date_end
      puts "Deal result date is #{date_start}"

      # 查询本机指定目录是否存在该日期的赛果文件
      result_file_html = File.expand_path("#{date_start.year}/#{date_start.month}/#{date_start.to_s}.html", RESULTPATH)
      result_file_csv = File.expand_path("#{date_start.year}/#{date_start.month}/#{date_start.to_s}.csv", RESULTPATH)
      puts "#{result_file_html}, #{File.exist?(result_file_html)}"
      unless File.exist?(result_file_html)
        # 从网站获取原始数据，保存成文本文件
        get_standard_xml(date_start.to_s)
        puts "Get #{date_start.to_s} result data from web!"
      end

      # 如果从web获取数据失败，或写入文件失败，则退出
      break unless File.exist?(result_file_html)

      unless File.exist?(result_file_csv)
        # 创建csv数据文件
        result_write_to_csv(result_file_html, result_file_csv)
        puts "Create simple #{date_start.to_s} result csv file."
      end

      break unless File.exist?(result_file_csv)

      # 读取赛果文本文件，分析处理,如果有新的赛事名称或新的球队名称，则暂停处理
      exit unless result_analyse(result_file_csv)

      # 准备处理下一个日期的数据
      date_start = date_start.succ

      exit
    end
  end
end
