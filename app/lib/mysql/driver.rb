
require 'rubygems'
require 'active_record'
require 'activerecord-import'

SQLLOGPATH = File.expand_path("../../lib/log/mysql.log", File.dirname(__FILE__))

ActiveRecord::Base.logger = Logger.new(SQLLOGPATH, 100, 32*1024*1024)

#####################
# MySQL数据库连接配置 #
#####################
ActiveRecord::Base.establish_connection(
  :adapter  => "mysql2",
  :host     => "localhost",
  :username => "root",
  :password => "mysql",
  :database => "huuuunt"
)

# 用于在直接使用SQL语句的场合（find_by_sql），通过$tab获取真正的table名
$tab = {}

### ！！！ 20130323，去除数据库表前缀cms_data_，从代码中看，无需修改。 ！！！ ###

###################################################################
# 生成数据库表对应的ActiveRecord类，数据库表通用前缀cms_data_不应在类名中 #
###################################################################
tables = []
ActiveRecord::Base.connection.execute("show tables").each do |table|
  tables << table[0]
  $tab["#{table[0].sub(/cms_data_/, '').singularize}"] = table[0]
end
# 将cms_data_match_infos转换成CmsDataMatchInfo
dest_tables = []
tables.each do |table|
  dest_tables << {
                   "class_name" => table.singularize.titleize.split.join,
                   "table_name" => table
                 }
end
# CmsDataMatches - CmsData = Match
# 将Match转换成继承ActiveRecord::Base的类，并对应数据库表“cms_data_matches”
# 其他数据库表对应的ActiveRecord::Base类以此类推
dest_tables.each do |names|
  class_name = names['class_name'].sub(/CmsData/, '')
  src = <<-END_SRC
    class #{class_name} < ActiveRecord::Base
      self.table_name = "#{names['table_name']}"
    end
  END_SRC
  eval src
end