
require 'excel_access'
require 'mysql_access'

class MatchInfoOutput
  FILEPATH = File.expand_path("../data/base/match.xls")

  MATCH_COLS_NAME = [
    "MatchNo", "MatchName", "Country", "Region", "MatchNameTn", "MatchNameEn",
    "MatchNameJp", "MatchType", "MatchColor", "IsStat", "Bet007MatchId",
    "Phases", "SeasonType", "",
    "MatchName1", "MatchName2", "MatchName3", "MatchName4", "MatchName5",
    "MatchName6", "MatchName7", "MatchName8", "MatchName9", "MatchName10"
  ]

  def initialize
    @excel = ExcelAccess.new()
    @excel.new_file(FILEPATH)
    @mysql = MysqlAccess.new()
  end

  def write_match_column_name
    line = 1
    start_col = "A"

    MATCH_COLS_NAME.each do |col_name|
      @excel.set_value(line, start_col, col_name)
      start_col.succ!
    end
  end

  def output_match_infos
    all_match_infos = @mysql.get_all_match_infos

    row = 1
    all_match_infos.each_hash do |match|
      match_id = match['match_id']
      name_utf8 = match['name_cn']
      name_tn_utf8 = match['name_tc']
      name_en = match['name_en']
      name_jp_utf8 = match['name_jp']
      match_color = match['match_color']
      is_stat = match['is_stat']
      country_id = match['country_id']
      bet007_match_id = match['bet007_match_id']
      phases = match['phases']
      season_type = match['season_type']

      name_gbk = Iconv.iconv("GBK", "UTF-8", name_utf8)
      country_utf8 = @mysql.get_country_name_by_id(country_id.to_i)
      country_gbk = Iconv.iconv("GBK", "UTF-8", country_utf8)
      name_tn_gbk = ''
      if name_tn_utf8!=nil && name_tn_utf8.size>0
        name_tn_gbk = Iconv.iconv("GBK", "UTF-8", name_tn_utf8)
      end
      name_jp_gbk = ''
      if name_jp_utf8!=nil && name_jp_utf8.size>0
        name_jp_gbk = Iconv.iconv("GBK", "UTF-8", name_jp_utf8)
      end
      #puts "country_utf8 = #{country_utf8}, country_gbk = #{country_gbk}"
      #puts "#{match_id}, #{name_gbk}, #{match_color}, #{is_stat}"
      row += 1
      @excel.set_value(row, "A", match_id)
      @excel.set_value(row, "B", name_gbk)
      @excel.set_value(row, "C", country_gbk)
      @excel.set_value(row, "E", name_tn_gbk)
      @excel.set_value(row, "F", name_en)
      @excel.set_value(row, "G", name_jp_gbk)
      @excel.set_value(row, "I", match_color)
      @excel.set_value(row, "J", is_stat)
      @excel.set_value(row, "K", bet007_match_id)
      @excel.set_value(row, "L", phases)
      @excel.set_value(row, "M", season_type)
    end
  end

  def output_match_other_infos
    all_match_other_infos = @mysql.get_all_match_other_infos

    current_col = 'O'
    old_match_id = 0
    
    all_match_other_infos.each_hash do |match|
      match_id = match['match_id']
      name_utf8 = match['name']
      name_gbk = Iconv.iconv("GBK", "UTF-8", name_utf8)
      
      if old_match_id != match_id
        current_col = 'O'
        old_match_id = match_id
      else
        current_col.succ!
      end
      row = match_id.to_i + 1
      #puts "#{row}, #{current_col}, #{name_gbk}"
      @excel.set_value(row, current_col, name_gbk)
    end
  end

  def output_match_data
    write_match_column_name
    output_match_infos
    output_match_other_infos
  end

  def close
    @excel.close
    @mysql.close
  end
end
