# 赛果数据处理CMD

require 'rubygems'
require 'cmdparse'

class ResultCmd < CmdParse::Command
  def initialize
    super('result', true)
    self.short_desc = "赛果数据处理程序"
    self.description = "赛果数据处理程序"
  end
end

class ResultDownloadCmd < CmdParse::Command
  def initialize
    super('download', false)
    self.short_desc = "赛果数据从指定网站中下载到本地硬盘"
    self.description = "赛果数据从指定网站中下载到本地硬盘"
  end

  def execute(args)

  end
end

class ResultPreprocessCmd < CmdParse::Command
    def initialize
    super('preprocess', false)
    self.short_desc = "赛果数据从指定网站中下载到本地硬盘"
    self.description = "赛果数据从指定网站中下载到本地硬盘"
  end

  def execute(args)

  end
end

class ResultUpdateCmd < CmdParse::Command
  def initialize
    super('update', false)
    self.short_desc = "将预处理好的赛果数据导入数据库"
    self.description = "将预处理好的赛果数据导入数据库"
  end

  def execute(args)

  end
end
