# 亚洲赔率数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/asia_ctrl'

class AsiaCmd < CmdParse::Command
  def initialize
    super('asia', true)
    self.short_desc = "亚洲赔率数据处理程序"
    self.description = "亚洲赔率数据处理程序"
  end
end

class AsiaDownloadCmd < CmdParse::Command
  def initialize
    super('download', false)
    self.short_desc = "亚洲赔率数据从指定网站中下载到本地硬盘"
    self.description = "亚洲赔率数据从指定网站中下载到本地硬盘"
  end

  def execute(args)
    AsiaCtrl.download(args)
  end
end

class AsiaPreprocessCmd < CmdParse::Command
    def initialize
    super('preprocess', false)
    self.short_desc = "检查亚洲赔率数据是否存在不能识别的赛事或球队信息"
    self.description = "检查亚洲赔率数据是否存在不能识别的赛事或球队信息"
  end

  def execute(args)
    AsiaCtrl.preprocess(args)
  end
end

class AsiaCheckResultCmd < CmdParse::Command
    def initialize
    super('checkresult', false)
    self.short_desc = "检查亚洲赔率数据是否在赛果数据中存在"
    self.description = "检查亚洲赔率数据是否在赛果数据中存在"
  end

  def execute(args)
    AsiaCtrl.resultcheck(args)
  end
end

class AsiaUpdateCmd < CmdParse::Command
  def initialize
    super('update', false)
    self.short_desc = "将预处理好的亚洲赔率数据导入数据库"
    self.description = "将预处理好的亚洲赔率数据导入数据库"
  end

  def execute(args)
    AsiaCtrl.update(args)
  end
end

class AsiaDPUCmd < CmdParse::Command
  def initialize
    super('dpu', false)
    self.short_desc = "下载亚洲赔率预处理数据导入数据库"
    self.description = "下载亚洲赔率预处理数据导入数据库"
  end

  def execute(args)
    AsiaCtrl.dpu(args)
  end
end
