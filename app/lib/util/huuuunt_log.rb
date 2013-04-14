# encoding: utf-8
require 'log4r'

###################
# log4r日志模块配置 #
###################
$logger = Log4r::Logger.new("Huuuunt")
# 日志记录等级设置
$logger.level = Log4r::DEBUG
formatter = Log4r::PatternFormatter.new(
  :pattern => "%C[%l]: %M"
  #:pattern => "%C[%l]:[%t] %M",
  #:date_format => "%Y/%m/%d %H:%M:%S"
)
logfile = Log4r::FileOutputter.new(
  "log",
  {
    :filename => File.expand_path("../log/huuuunt.log", File.dirname(__FILE__)),
    :formatter => formatter,
    :trunc => TRUE   # 下次运行是否先清空原先的日志文件内容
  })
$logger.outputters = logfile
