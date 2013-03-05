# 赛果数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/result_ctrl'

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
    ResultCtrl.download(args)
  end
end

class ResultPreprocessCmd < CmdParse::Command
    def initialize
    super('preprocess', false)
    self.short_desc = "检查赛果数据是否存在不能识别的赛事或球队信息"
    self.description = "检查赛果数据是否存在不能识别的赛事或球队信息"
  end

  def execute(args)
    ResultCtrl.preprocess(args)
  end
end

class ResultImportCmd < CmdParse::Command
  def initialize
    super('import', false)
    self.short_desc = "将预处理好的赛果数据导入数据库"
    self.description = "将预处理好的赛果数据导入数据库"
  end

  def execute(args)
    ResultCtrl.import(args)
  end
end

class ResultDPUCmd < CmdParse::Command
  def initialize
    super('dpu', false)
    self.short_desc = "下载赛果预处理数据导入数据库"
    self.description = "下载赛果预处理数据导入数据库"
  end

  def execute(args)
    ResultCtrl.dpu(args)
  end
end
