# 赛事名称等数据导入导出处理程序

require 'rubygems'
require 'spreadsheet'

require 'mysql/match'
require 'util/excel'

class MatchCtrl

  include Huuuunt::Excel
  
  MatchInfoFile = File.expand_path("../../data/base/match.xls", File.dirname(__FILE__))
  # match excel 字段名称
  MATCH_COLS_NAME = [
    "MatchNo", "MatchName", "Country", "Region", "MatchNameTn", "MatchNameEn",
    "MatchNameJp", "MatchType", "MatchColor", "NeedImport", "Bet007MatchId",
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
    match_sheet = book.worksheet("match")
    country_sheet = book.worksheet("country")
        
    # 写入countries数据库表    
    ActiveRecord::Base.connection.execute("TRUNCATE table #{$tab['country']}")
    countries = []
    country_sheet.each do |row|
      next if row[0] == "CountryId"      
      countries << Country.new(:id => row[0],
                               :name_cn => row[1],
                               :name_tw => row[2],
                               :name_en => row[3],
                               :name_jp => row[4],
                               :flag => row[5])
    end
    Country.import(countries)
   
    # 写入match_infos数据库表
    ActiveRecord::Base.connection.execute("TRUNCATE table #{$tab['match']}")
    match_infos = []
    match_sheet.each do |row|
      next if row[1] == "MatchName"
      country_id = Country.where("name_cn = ?", row[2]).first.id if get_cell_val(row[2])
      match_infos << Match.new(:match_id => row[0],
                               :name_cn => row[1],
                               :name_tw => row[4],
                               :name_en => row[5],
                               :name_jp => row[6],
                               :match_color => row[8],
                               :need_import => row[9],
                               :country_id => country_id,
                               :bet007_match_id => row[10],
                               :phases => row[11],
                               :season_type => row[12],
                               :name1  => get_cell_val(row[14]),
                               :name2  => get_cell_val(row[15]),
                               :name3  => get_cell_val(row[16]),
                               :name4  => get_cell_val(row[17]),
                               :name5  => get_cell_val(row[18]),
                               :name6  => get_cell_val(row[19]),
                               :name7  => get_cell_val(row[20]),
                               :name8  => get_cell_val(row[21]),
                               :name9  => get_cell_val(row[22]),
                               :name10 => get_cell_val(row[23])
                              )
    end
    Match.import(match_infos)

#    # 写入match_other_infos数据库表
#    ActiveRecord::Base.connection.execute("TRUNCATE table #{$tab['match_other']}")
#    match_others = []
#    match_sheet.each do |row|
#      next if row[1] == "MatchName"
#      start = 14
#      while get_cell_val(row[start])
#        match_others << MatchOther.new(:match_id => row[0], :name => row[start])
#        start += 1
#      end
#    end
#    MatchOther.import(match_others)
  end

  # 将赛事名称等相关数据导出到Excel中
  def self.export(args)
    # 转存原有match.xls文件，文件名加上时间戳
    FileUtils.mv(MatchInfoFile, MatchInfoFile+".#{Time.now.to_i}") if File.exist?(MatchInfoFile)

    # 创建新match.xls文件，并写入每列字段名称
    book = Spreadsheet::Workbook.new
    match_sheet = book.create_worksheet(:name => "match")
    country_sheet = book.create_worksheet(:name => "country")

    MATCH_COLS_NAME.each_with_index do |col_name, index|
      match_sheet[0, index] = col_name
    end
    COUNTRY_COLS_NAME.each_with_index do |col_name, index|
      country_sheet[0, index] = col_name
    end

    # 读取数据库表match_infos，并按字段名称写入match中
    Match.all.each do |m|
      index = m.match_id
      match_sheet[index, 0] = m.match_id
      match_sheet[index, 1] = m.name_cn

      match_sheet[index, 4] = m.name_tw
      match_sheet[index, 5] = m.name_en
      match_sheet[index, 6] = m.name_jp

      match_sheet[index, 8] = m.match_color
      match_sheet[index, 9] = m.need_import
      match_sheet[index, 10] = m.bet007_match_id
      match_sheet[index, 11] = m.phases
      match_sheet[index, 12] = m.season_type

      match_sheet[index, 14] = m.name1
      match_sheet[index, 15] = m.name2
      match_sheet[index, 16] = m.name3
      match_sheet[index, 17] = m.name4
      match_sheet[index, 18] = m.name5
      match_sheet[index, 19] = m.name6
      match_sheet[index, 20] = m.name7
      match_sheet[index, 21] = m.name8
      match_sheet[index, 22] = m.name9
      match_sheet[index, 23] = m.name10
    end

    # country信息需要读取countries数据表,写入match中
    Match.get_country_name.each do |m|
      index = m.match_id
      match_sheet[index, 2] = m.country_name
    end

#    # 读取match_other_infos数据库表，按字段名称写入match中
#    c = Hash.new(14)
#    MatchOther.order("match_id").each do |mo|
#      index = mo.match_id
#      match_sheet[index, c[index]] = mo.name
#      c[index] += 1
#    end

    # 读取countries数据库表，写入country中
    Country.all.each do |c|
      index = c.id
      country_sheet[index, 0] = c.id
      country_sheet[index, 1] = c.name_cn
      country_sheet[index, 2] = c.name_tw
      country_sheet[index, 3] = c.name_en
      country_sheet[index, 4] = c.name_jp
      country_sheet[index, 5] = c.flag
    end

    # 写入match.xls文件
    book.write(MatchInfoFile)
  end

  def self.check_duplicate_name(args)
    Match.check_duplicate_name
  end
end