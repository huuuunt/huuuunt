# 欧洲赔率数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/europe_ctrl'

class EuropeCmd < CmdParse::Command
  def initialize
    super('europe', true)
    self.short_desc = "欧洲赔率数据处理程序"
    self.description = "欧洲赔率数据处理程序"
  end
end

class EuropeDownloadCmd < CmdParse::Command
  def initialize
    super('download', false)
    self.short_desc = "欧洲赔率数据从指定网站中下载到本地硬盘"
    self.description = "欧洲赔率数据从指定网站中下载到本地硬盘"
  end

  def execute(args)
    EuropeCtrl.download(args)
  end
end

class EuropePreprocessCmd < CmdParse::Command
    def initialize
    super('preprocess', false)
    self.short_desc = "检查欧洲赔率数据是否存在不能识别的赛事或球队信息"
    self.description = "检查欧洲赔率数据是否存在不能识别的赛事或球队信息"
  end

  def execute(args)
    EuropeCtrl.preprocess(args)
  end
end

class EuropeCheckResultCmd < CmdParse::Command
    def initialize
    super('checkresult', false)
    self.short_desc = "检查欧洲赔率数据是否在赛果数据中存在"
    self.description = "检查欧洲赔率数据是否在赛果数据中存在"
  end

  def execute(args)
    EuropeCtrl.resultcheck(args)
  end
end

class EuropeUpdateCmd < CmdParse::Command
  def initialize
    super('update', false)
    self.short_desc = "将预处理好的欧洲赔率数据导入数据库"
    self.description = "将预处理好的欧洲赔率数据导入数据库"
  end

  def execute(args)
    EuropeCtrl.update(args)
  end
end

class EuropeDPUCmd < CmdParse::Command
  def initialize
    super('dpu', false)
    self.short_desc = "下载欧洲赔率预处理数据导入数据库"
    self.description = "下载欧洲赔率预处理数据导入数据库"
  end

  def execute(args)
    EuropeCtrl.dpu(args)
  end
end