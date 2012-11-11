# 赛事名称等数据导入导出处理程序

require 'rubygems'
require 'spreadsheet'

require 'mysql/mysql_access'

class Match

  

  class << self
    # 将赛事名称等相关数据导入数据库
    def import(args)
      @mysql = MysqlAccess.new()
      @mysql.truncate_table_match_infos

      @workbook = Spreadsheet.open(Huuuunt::MatchPathFile, 'r')

      line = 2
      until @excel.get_value(line, "A") == nil
        yield line
        line += 1
      end
    end

    # 将赛事名称等相关数据导出到Excel中
    def export(args)
      
    end
  end
end