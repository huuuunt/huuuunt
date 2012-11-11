require 'rubygems'
require 'open-uri'
require 'net/http'
require 'iconv'
require 'date'
require 'fileutils'
require 'hpricot'
require 'huuuunt_util'

class MatchesUpdate
  MATCHESPATH = "../data/matches/"

  def initialize
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new()
  end

  def close
    @mysql.close
  end

  def get_standard_xml(bet007_match_id, season, phase, match_id)
    begin
      bet007_season = season
      if season.size==4
        bet007_season = season + '-' + season.succ
      end
      # 特殊情况
      if bet007_match_id.to_i==37
        bet007_match_id = "37_87"
      end
      if bet007_match_id.to_i==40
        bet007_match_id = "40_261"
      end
      if bet007_match_id.to_i==9
        bet007_match_id = "9_132"
      end
      if bet007_match_id.to_i==16
        bet007_match_id = "16_98"
      end
      if bet007_match_id.to_i==5
        #bet007_match_id = "5_114"
      end
      # http://info.bet007.com/league_match/league_vs/2008-2009/36_1.htm
      matches_url = "http://info.bet007.com/league_match/league_vs/#{bet007_season}/#{bet007_match_id}_#{phase}.htm"
      puts matches_url
      #matches_htm = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(matches_url))
      matches_htm = Net::HTTP.get(URI.parse(matches_url))

      # 创建season目录，如2008或2008-2009
      # 创建match_id目录，如英超创建目录36
      # 目录结构：../data/matches/2008-2009/36/1.htm
      matches_file_path = File.expand_path("#{season}/#{match_id}/#{phase}.htm", MATCHESPATH)
      #puts "#{matches_file_path}"
      puts "#{File.expand_path("#{season}/", MATCHESPATH)}"
      unless File.directory?(File.expand_path("#{season}/", MATCHESPATH))
        FileUtils.mkdir(File.expand_path("#{season}/", MATCHESPATH))
      end
      unless File.directory?(File.expand_path("#{season}/#{match_id}/", MATCHESPATH))
        FileUtils.mkdir(File.expand_path("#{season}/#{match_id}/", MATCHESPATH))
      end
      File.open(matches_file_path, "w") do |f|
        f.puts matches_htm
      end
    rescue Exception=>ex
      puts ex
      return nil
    end
  end

  def matches_read(filepath, match_year, season_type)
    if season_type.to_i!=1 && season_type.to_i!=2
      puts "season_type(#{season_type}) is error!"
      return
    end
    year1, year2 = match_year.split('-')
    matches_html = File.read(filepath)
    doc = Hpricot(matches_html)
    count = 0
    schedule = doc.search("#Table3")
    matches = schedule/'tr'
    matches.each do |match|
      count+=1
      next if count<=2
      details = match/'td'
      break if details.size==1     # 不必导入下一轮赛事数据

      phase = (details[0]/'div')[0].inner_text
      t_match_datetime = (details[1]/'div')[0].inner_html
      t_match_home = ((details[2]/'div')[0]/'a')[0].inner_html
      match_goal =  details[3].inner_text
      t_match_away =  ((details[4]/'div')[0]/'a')[0].inner_html
      rq_all = details[5].inner_text
      dxq_all = details[7].inner_text
      match_half_goal = details[10].inner_text

      match_home = t_match_home.split('<')[0]
      match_away = t_match_away.split('<')[0]

      t_match_date, t_match_time = t_match_datetime.split('<')
      match_time = t_match_time.split('>')[1]
      match_month = t_match_date.split('-')[0].to_i

      match_datetime = ''
      if season_type.to_i == 1
        if match_month < 7
          match_datetime = "#{year2}-#{t_match_date} #{match_time}"
        else
          match_datetime = "#{year1}-#{t_match_date} #{match_time}"
        end
      elsif season_type.to_i == 2
        match_datetime = "#{year1}-#{t_match_date} #{match_time}"
      end

      goal1, goal2 = match_goal.split('-')
      h_goal1, h_goal2 = match_half_goal.split('-')

      #puts "#{phase}"
      #puts "#{match_datetime}"
      #puts "#{Iconv.iconv("GBK","UTF-8",match_home)[0]}"
      #puts "#{goal1}-#{goal2}"
      #puts "#{Iconv.iconv("GBK","UTF-8",match_away)[0]}"
      #puts "#{rq_all}"
      #puts "#{dxq_all}"
      #puts "#{h_goal1}-#{h_goal2}"
      #puts "\n"

      yield "#{phase};#{match_datetime};#{match_home};#{match_goal};#{match_away};#{rq_all};#{dxq_all};#{match_half_goal}"
        
    end
  end

  def write_to_csv(file_html, file_csv, match_year, season_type)
    csv_handle = File.open(file_csv, "w")
    matches_read(file_html, match_year, season_type) do |match|
      csv_handle.puts match
    end
    csv_handle.close
  end

  def matches_cvs_read(file_csv)
    f = File.open(file_csv, "r")
    until f.eof?
      yield f.readline
    end
    f.close
  end

  def matches_new_team_exist?(file_csv, match_id)
    new_team_exist = false
    matches_cvs_read(file_csv) do |match|
      details = match.split(';')
      team1_name_gbk = details[2]
      team2_name_gbk = details[4]
      #puts "#{Iconv.iconv("GBK", "UTF-8", team1_name_gbk)[0]}, #{Iconv.iconv("GBK", "UTF-8", team2_name_gbk)[0]}"
      new_team_exist = @util.new_team_home_away?(team1_name_gbk, team2_name_gbk, match_id, true)
    end
    return new_team_exist
  end

  def matches_insert(file_csv, match_year, match_id)
    matches_cvs_read(file_csv) do |match|
      details = match.split(';')

      phase = details[0]
      match_datetime = details[1]
      team1_name_utf8 = details[2]
      team2_name_utf8 = details[4]

      team1_id = @mysql.get_team_id_by_team_name(team1_name_utf8)
      team2_id = @mysql.get_team_id_by_team_name(team2_name_utf8)

      unless @mysql.is_matches_exist?(match_year, phase, match_id, team1_id, team2_id)
        puts "insert #{match_year},#{phase},#{match_id},#{team1_id},#{team2_id}"
        @mysql.insert_base_matches(match_year, phase, match_id, match_datetime, team1_id, team2_id)
      end
    end
    @mysql.commit
  end
  
  def matches_analyse(file_csv, match_year, match_id)
    puts "Deal matches #{file_csv}, #{match_year}, #{match_id}"
    if matches_new_team_exist?(file_csv, match_id)
      return nil
    end
    matches_insert(file_csv, match_year, match_id)
  end

  def do_update(season_type, match_year, match_set)
    # 获取要统计的赛事信息，包括“bet007_match_id”，“phases”，“season_type”，“new season”
    if season_type!=1 && season_type!=2
      puts "season_type must equal 1 or 2"
      return
    end
    if season_type==1
      match_year = match_year + '-' + match_year.next
    end
    
    if match_set==nil || match_set.size==0
      puts "Enter all matches deal."
      match_set = @mysql.get_match_season_info(season_type)
    else
      match_set = @mysql.get_special_match_season_info(season_type, match_set.join(','))
    end

    # 顺序处理每个联赛的赛程数据
    match_set.each do |item|
      match_id = item[0]
      #match_name = item[1]
      bet007_match_id = item[2]
      phases = item[3]
      season_type = item[4]
      latest_season = match_year
      puts "#{match_id}, #{bet007_match_id}, #{phases}, #{season_type}, #{latest_season}"

      next if phases.to_i==0  # 未填写轮次的联赛，不处理

      new_season = latest_season
      # 根据season_type和new season，计算出当前season
      #if season_type=='1'
      #  tmp = latest_season.split('-')
      #  new_season = tmp[1] + '-' + tmp[1].succ
      #elsif season_type=='2'
      #  new_season = latest_season.succ
      #else
      #  puts "season_type is error."
      #  break
      #end
      puts "#{new_season}, #{phases.to_i}"

      count = 1
      while count <= phases.to_i
        # 判断该赛程数据文件是否已经存在
        file_html = File.expand_path("#{new_season}/#{match_id}/#{count}.htm", MATCHESPATH)
        puts "#{file_html}, #{File.exist?(file_html)}"
        # 从web获取该联赛当前赛季的所有赛程
        unless File.exist?(file_html)
          get_standard_xml(bet007_match_id, new_season, count, match_id)
          puts "Get #{match_id}, #{new_season}, #{count} matches from web"
        end

        # 如果没有成功获取，则退出
        break unless File.exist?(file_html)

        file_csv = File.expand_path("#{new_season}/#{match_id}/#{count}.csv", MATCHESPATH)
        unless File.exist?(file_csv)
          # 创建csv数据文件
          write_to_csv(file_html, file_csv, new_season, season_type)
          puts "Create simple #{new_season}/#{match_id}/#{count} phase csv file."
        end

        break unless File.exist?(file_csv)
        
        # 读取分析读取的赛程数据文件
        matches_analyse(file_csv, new_season, match_id)
        
        count += 1

        #break        
      end      
      #break
    end    
  end
end
