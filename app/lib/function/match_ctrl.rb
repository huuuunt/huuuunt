# 赛事名称等数据导入导出处理程序

require 'rubygems'
require 'spreadsheet'

require 'mysql/mysql_driver'
require 'mysql/match_info'
require 'util/excel'

class MatchCtrl

  include Huuuunt::Excel
  
  MatchInfoFile = File.expand_path("../../data/base/match.xls", File.dirname(__FILE__))
  # match excel 字段名称
  MATCH_COLS_NAME = [
    "MatchNo", "MatchName", "Country", "Region", "MatchNameTn", "MatchNameEn",
    "MatchNameJp", "MatchType", "MatchColor", "IsStat", "Bet007MatchId",
    "Phases", "SeasonType", "",
    "MatchName1", "MatchName2", "MatchName3", "MatchName4", "MatchName5",
    "MatchName6", "MatchName7", "MatchName8", "MatchName9", "MatchName10"
  ]
  COUNTRY_COLS_NAME = [
    "CountryId", "CountryNameCn", "CountryNameTw", "CountryNameEn", "CountryNameJp", "Logo"
  ]
  
  # 将赛事名称等相关数据导入数据库
  def self.import(args)
    #$logger.debug("MatchInfoFile = #{MatchInfoFile}")
    # 读取excel数据，保存到hash结构中
    book = Spreadsheet.open(MatchInfoFile, 'r')
    sheet1 = book.worksheet("match")
    sheet2 = book.worksheet("country")
        
    # 写入countries数据库表
    ActiveRecord::Base.connection.execute("TRUNCATE table countries")
    sheet2.each do |row|
      next if row[0] == "CountryId"      
      Country.create(:id => row[0],
                     :name_cn => row[1],
                     :name_tw => row[2],
                     :name_en => row[3],
                     :name_jp => row[4],
                     :flag => row[5])
    end
   
    # 写入match_infos数据库表
    ActiveRecord::Base.connection.execute("TRUNCATE table match_infos")
    sheet1.each do |row|
      next if row[1] == "MatchName"
      country_id = Country.where("name_cn = ?", row[2]).first.id if get_cell_val(row[2])
      MatchInfo.create(:match_id => row[0],
                       :name_cn => row[1],
                       :name_tc => row[4],
                       :name_en => row[5],
                       :name_jp => row[6],
                       :match_color => row[8],
                       :is_stat => row[9],
                       :country_id => country_id,
                       :bet007_match_id => row[10],
                       :phases => row[11],
                       :season_type => row[12])
    end

    # 写入match_other_infos数据库表
    ActiveRecord::Base.connection.execute("TRUNCATE table match_other_infos")
    sheet1.each do |row|
      next if row[1] == "MatchName"
      start = 14
      while get_cell_val(row[start])
        MatchOtherInfo.create(:match_id => row[0], :name => row[start])
        start += 1
      end
    end
  end

  # 将赛事名称等相关数据导出到Excel中
  def self.export(args)
    # 转存原有match.xls文件，文件名加上时间戳
    FileUtils.mv(MatchInfoFile, MatchInfoFile+".#{Time.now.to_i}") if File.exist?(MatchInfoFile)

    # 创建新match.xls文件，并写入每列字段名称
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet(:name => "match")
    sheet2 = book.create_worksheet(:name => "country")

    MATCH_COLS_NAME.each_with_index do |col_name, index|
      sheet1[0, index] = col_name
    end
    COUNTRY_COLS_NAME.each_with_index do |col_name, index|
      sheet2[0, index] = col_name
    end

    # 读取数据库表match_infos，并按字段名称写入match中
    MatchInfo.all.each do |m|
      index = m.match_id
      sheet1[index, 0] = m.match_id
      sheet1[index, 1] = m.name_cn

      sheet1[index, 4] = m.name_tc
      sheet1[index, 5] = m.name_en
      sheet1[index, 6] = m.name_jp

      sheet1[index, 8] = m.match_color
      sheet1[index, 9] = m.is_stat
      sheet1[index, 10] = m.bet007_match_id
      sheet1[index, 11] = m.phases
      sheet1[index, 12] = m.season_type
    end

    # country信息需要读取countries数据表,写入match中
    MatchInfo.getCountryName.each do |m|
      index = m.match_id
      sheet1[index, 2] = m.country_name
    end

    # 读取match_other_infos数据库表，按字段名称写入match中
    c = Hash.new(14)
    MatchOtherInfo.order("match_id").each do |mo|
      index = mo.match_id
      sheet1[index, c[index]] = mo.name
      c[index] += 1
    end

    # 读取countries数据库表，写入country中
    Country.all.each do |c|
      index = c.id
      sheet2[index, 0] = c.id
      sheet2[index, 1] = c.name_cn
      sheet2[index, 2] = c.name_tw
      sheet2[index, 3] = c.name_en
      sheet2[index, 4] = c.name_jp
      sheet2[index, 5] = c.flag
    end

    # 写入match.xls文件
    book.write(MatchInfoFile)
  end
end