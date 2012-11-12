
# 导入历年赛季各联赛中，因为各种原因造成球队扣除联赛积分的情况

class ScorePoint
  SCOREPOINTPATH = "../data/scoreothers/"
  
  def initialize
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new()
    @excel = ExcelAccess.new()    
  end

  def close
    @mysql.close
  end

  def load_score_point(filepath)
    @excel.open_file(filepath)
    line = 1
    # 使用insert和update来更新数据
    while 1
      #puts "line = #{line}, A = #{@excel.get_value(line, "A")}"
      break if @excel.get_value(line, "A") == nil

      season = @excel.get_value(line, 'A') || ''
      matchname_gbk = @excel.get_value(line, 'B') || ''
      teamname_gbk = @excel.get_value(line, 'C') || ''
      reason_gbk = @excel.get_value(line, 'D') || ''
      point = @excel.get_value(line, 'E') || 0

      if season.class == Float
        season = season.to_i
      end

      next if season.to_s.length==0

      matchname_utf8 = Iconv.iconv("UTF-8", "GBK", matchname_gbk)
      teamname_utf8 = Iconv.iconv("UTF-8", "GBK", teamname_gbk)
      match_id = @mysql.get_match_id_by_match_name(matchname_utf8)
      team_id = @mysql.get_team_id_by_team_name(teamname_utf8)

      if match_id==0 || team_id==0
        puts "Can't find match_id(#{matchname_utf8},#{match_id}) or team_id(#{teamname_utf8},#{team_id})"
        exit
      end
      
      reason_utf8 = Iconv.iconv("UTF-8", "GBK", reason_gbk)
      point = point.to_i

      # 将球队扣分数据记入数据库
      @mysql.insert_or_update_scorepoint(season, match_id, team_id, reason_utf8, point)

      # 修改数据库中积分榜上point字段数据
      @mysql.update_score_point(season, match_id, team_id, point)

      line += 1
    end
  end

  # 更新指定赛季的某支球队的联赛积分的扣分情况
  # season： '2010-2011' 可以表示"2010赛季和2010-2011赛季"
  def do_update(season)
    # 判断是否存在相应的文件
    scorepoint_path = File.expand_path("#{season}.xls", SCOREPOINTPATH)
    puts "scorepoint_path: #{scorepoint_path}"
    exit unless File.exist?(scorepoint_path)
    
    # 读取指定赛季的文件数据，并导入数据库
    load_score_point(scorepoint_path)
  end
end