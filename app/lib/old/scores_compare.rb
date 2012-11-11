
class ScoresCompare
  SCORESPATH = "../data/scores/"

  GOOOOAL_PARAMS = {
    1 => [4, 6],    # 英超
    2 => [21, 7],    # 英冠
    9 => [1, 19],    # 意甲
    10 => [20, 20],   # 意乙
    18 => [2, 14],   # 西甲
    19 => [31, 15],   # 西乙
    24 => [3, 1],   # 德甲
    25 => [17, 2],   # 德乙
    28 => [5, 23],   # 法甲
    29 => [70, 24],   # 法乙
    32 => [30, 31],   # 葡超
    34 => [12, 44],   # 苏超
    38 => [6, 28],   # 荷甲
    40 => [33, 41],   # 比甲
    62 => [51, 50],   # 丹麦超
    69 => [52, 69],   # 奥甲
    42 => [34, 54],   # 瑞典超
    54 => [37, 62],   # 芬超
    56 => [35, 58],   # 挪超
    76 => [55, 72],   # 俄超
    111 => [56, 109],  # 巴西甲
    127 => [138, 117]   # 日职联
  }
  
  def initialize
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new()
  end

  def close
    @mysql.close
  end

  def get_standard_xml(season, match_id)
    begin
      scores_file_path = File.expand_path("#{season}/#{match_id}.htm", SCORESPATH)
      if File.exist?(scores_file_path)
        puts "#{scores_file_path} exist!"
        return
      end
      gooooal_season = season
      if gooooal_season.index('-')
        gooooal_season = gooooal_season.split('-')[0]
      end
      # http://app.gooooal.com/competition.do?lid=4&sid=2009&pid=6&lang=tr
      scores_url = "http://app.gooooal.com/competition.do?lid=#{GOOOOAL_PARAMS[match_id][0]}&sid=#{gooooal_season}&pid=#{GOOOOAL_PARAMS[match_id][1]}&lang=tr"
      puts scores_url
      #scores_htm = Net::HTTP::Proxy('192.168.21.2', 80).get(URI.parse(scores_url))
      scores_htm = Net::HTTP.get(URI.parse(scores_url))

      # 创建season目录，如2008或2008-2009
      # 目录结构：../data/scores/2008-2009/36.htm
      
      #puts "#{matches_file_path}"
      puts "#{File.expand_path("#{season}/", SCORESPATH)}"
      unless File.directory?(File.expand_path("#{season}/", SCORESPATH))
        FileUtils.mkdir(File.expand_path("#{season}/", SCORESPATH))
      end
      File.open(scores_file_path, "w") do |f|
        f.puts scores_htm
      end
    rescue Exception=>ex
      puts "(HTTP error) #{ex}"
      exit
    end
  end

  def score_htm_read(htm_file_path)
    scores_html = File.read(htm_file_path)
    doc = Hpricot(scores_html)
    tables = [0,1,2,3]
    tables.each do |table_index|
      table = doc.search("#tb_data_#{table_index}")
      scores = table/'tr'
      count = 0
      scores.each do |score|
        count += 1
        next if count==1
        content = ""
        details = score/'td'
        #d_index = 0
        details.each do |detail|
          #if d_index==1
          #  team_id = @mysql.get_team_id_by_team_name(detail.inner_text.strip)
          #  content += team_id + ","
          #else
            content += detail.inner_text.strip + ","
          #end
          #d_index += 1
        end
        yield content
      end
      yield "#\n"
    end
  end

  def convert_html2csv(csv_file_path, htm_file_path)
    if File.exist?(csv_file_path)
      return
    end
    csv_handle = File.open(csv_file_path, "w")
    score_htm_read(htm_file_path) do |score|
      csv_handle.puts score
    end
    csv_handle.close
  end

  def compare_score_detail(score, score_d)
    score.each_index do |index|
      next if index==0
      if score[index]!=score_d[index]
        puts "#{index} not equal!"
        puts "score[#{index}] = #{score[index]}"
        puts "score_d[#{index}] = #{score_d[index]}"
      end
    end
  end

  def compare_scores(csv_file_path, match_id, match_year)
    score_all = []
    score_h = []
    score_a = []
    score_6 = []
    score_all_d = []
    score_h_d = []
    score_a_d = []
    score_6_d = []

    score_type = 0

    # 读取并处理gooooal网站上获取的积分榜数据
    f = File.open(csv_file_path, "r")
    until f.eof?
      line = f.readline
      if line =~ /#/
        score_type += 1
      end
      items = line.split(',')
      team_id = @mysql.get_team_id_by_team_name(items[1])
      data = "#{team_id},#{items[2]},#{items[3]},#{items[4]},#{items[5]},#{items[6]},#{items[7]},#{items[8]},#{items[9]}"

      rank = items[0].to_i
      if score_type == 0
        score_all[rank] = data
      elsif score_type == 1
        score_h[rank] = data
      elsif score_type == 2
        score_a[rank] = data
      elsif score_type == 3
        score_6[rank] = data
      end
    end
    f.close

    # 读取数据库中的积分榜数据
    # 总积分榜
    score_all_arr = @mysql.get_scores_all_by_season(match_id, match_year)
    index = 0
    score_all_arr.each do |items|
      index += 1
      score_all_d[index] = "#{items[0]},#{items[1]},#{items[2]},#{items[3]},#{items[4]},#{items[5]},#{items[6]},#{items[7]},#{items[8]}"
    end

    # 主场积分榜
    score_h_arr = @mysql.get_scores_home_by_season(match_id, match_year)
    index = 0
    score_h_arr.each do |items|
      index += 1
      score_h_d[index] = "#{items[0]},#{items[1]},#{items[2]},#{items[3]},#{items[4]},#{items[5]},#{items[6]},#{items[7]},#{items[8]}"
    end

    # 客场积分榜
    score_a_arr = @mysql.get_scores_away_by_season(match_id, match_year)
    index = 0
    score_a_arr.each do |items|
      index += 1
      score_a_d[index] = "#{items[0]},#{items[1]},#{items[2]},#{items[3]},#{items[4]},#{items[5]},#{items[6]},#{items[7]},#{items[8]}"
    end

    # 近6轮积分榜
    score_6_arr = @mysql.get_scores_6_by_season(match_id, match_year)
    index = 0
    score_6_arr.each do |items|
      index += 1
      score_6_d[index] = "#{items[0]},#{items[1]},#{items[2]},#{items[3]},#{items[4]},#{items[5]},#{items[6]},#{items[7]},#{items[8]}"
    end
    puts "#{match_id}: compare score all"
    compare_score_detail(score_all, score_all_d)
    puts "#{match_id}: compare score home"
    compare_score_detail(score_h, score_h_d)
    puts "#{match_id}: compare score away"
    compare_score_detail(score_a, score_a_d)
    puts "#{match_id}: compare score 6"
    compare_score_detail(score_6, score_6_d)

  end

  def do_compare(match_year, match_set)
    match_set.each do |match_id|
      get_standard_xml(match_year, match_id)

      htm_file_path = File.expand_path("#{match_year}/#{match_id}.htm", SCORESPATH)
      csv_file_path = File.expand_path("#{match_year}/#{match_id}.csv", SCORESPATH)
      convert_html2csv(csv_file_path, htm_file_path)

      compare_scores(csv_file_path, match_id, match_year)

      #break
    end
  end
end
