
require 'excel_access'
require 'mysql_access'

class MatchInfoLoad
  FILEPATH = File.expand_path("../data/base/match.xls")

  def initialize
    @excel = ExcelAccess.new()
    @excel.open_file(FILEPATH)
    @mysql = MysqlAccess.new()
  end

  def is_end?(line)
    @excel.get_value(line, "A") == nil
  end

  def read_all_lines
    line = 2
    until is_end?(line)
      yield line
      line += 1
    end
  end

  def load_countries
    @mysql.truncate_table("countries")

    read_all_lines do |line|
      country_gbk = @excel.get_value(line, 'C') || ''

      next if country_gbk.length==0

      country_utf8 = Iconv.iconv("UTF-8", "GBK", country_gbk)

      @mysql.insert_country(country_utf8) if @mysql.country_is_not_exist?(country_utf8)      
    end
  end

  def load_match_infos
    # reload table match_infos
    @mysql.truncate_table_match_infos

    read_all_lines do |line|
      match_id = @excel.get_value(line, "A") || 0
      gbk_name_cn = @excel.get_value(line, "B") || ""
      country_gbk = @excel.get_value(line, "C") || ""
      gbk_name_tn = @excel.get_value(line, "E") || ""
      name_en = @excel.get_value(line, "F") || ""
      gbk_name_jp = @excel.get_value(line, "G") || ""
      match_color = @excel.get_value(line, "I") || '#000000'
      is_stat = @excel.get_value(line, "J") || 0
      bet007_match_id = @excel.get_value(line, "K") || 0
      phases = @excel.get_value(line, "L") || 0
      season_type = @excel.get_value(line, "M") || 0

      #puts "#{match_id}, #{gbk_name_cn}, #{match_color}, #{is_stat}"
      name_cn = Iconv.iconv("UTF-8", "GBK", gbk_name_cn)
      
      name_tn = ''
      if gbk_name_tn!=nil && gbk_name_tn.length>0
        name_tn = Iconv.iconv("UTF-8", "GBK", gbk_name_tn)
      end
      
      name_jp = ''
      if gbk_name_jp!=nil && gbk_name_jp.length>0
        name_jp = Iconv.iconv("UTF-8", "GBK", gbk_name_jp)
      end

      country_id = 0
      if country_gbk!=nil && country_gbk.length > 0
        country_utf8 = Iconv.iconv("UTF-8", "GBK", country_gbk)
        country_id = @mysql.get_country_id_by_name(country_utf8)
      end

      @mysql.insert_match_infos(match_id, name_cn, name_tn, name_en,
                                name_jp, match_color, is_stat,
                                country_id, bet007_match_id, phases,
                                season_type)
    end

    @mysql.commit
  end

  def load_match_other_infos
    # reload table match_other_infos
    @mysql.truncate_table_match_other_infos

    read_all_lines do |line|
      match_id = @excel.get_value(line, "A") || 0

      names_gbk = []
      start_col = 'O'
      until start_col == 'Z'
        names_gbk << @excel.get_value(line, start_col)
        start_col.succ!
      end
      names_gbk.compact!
      names_gbk.each do |name_gbk|
        if name_gbk.size > 0
          name = Iconv.iconv("UTF-8", "GBK", name_gbk)
          @mysql.insert_match_other_infos(match_id, name)
        end
      end
    end

    @mysql.commit
  end
  
  def load_match_data
    load_countries
    load_match_infos
    load_match_other_infos
  end

  def close
    @excel.close
    @mysql.close
  end
end