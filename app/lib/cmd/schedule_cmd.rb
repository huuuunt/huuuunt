# 赛程数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/schedule_ctrl'

class ScheduleCmd < CmdParse::Command
  def initialize
    super('schedule', true)
    self.short_desc = "赛程数据处理程序"
    self.description = "赛程数据处理程序"
  end
end

class ScheduleDownloadCmd < CmdParse::Command
  def initialize
    super('download', false)
    self.short_desc = "赛程数据从指定网站中下载到本地硬盘"
    self.description = "赛程数据从指定网站中下载到本地硬盘"
  end

  def execute(args)
    ScheduleCtrl.download(args)
  end
end

class SchedulePreprocessCmd < CmdParse::Command
    def initialize
    super('preprocess', false)
    self.short_desc = "检查赛程数据是否存在不能识别球队信息"
    self.description = "检查赛程数据是否存在不能识别球队信息"
  end

  def execute(args)
    ScheduleCtrl.preprocess(args)
  end
end

class ScheduleImportCmd < CmdParse::Command
  def initialize
    super('import', false)
    self.short_desc = "将预处理好的赛程数据导入数据库"
    self.description = "将预处理好的赛程数据导入数据库"
  end

  def execute(args)
    ScheduleCtrl.import(args)
  end
end

# 输入参数规则
# 1、必须输入赛季，如2003、2003-2004，两种赛季格式必须区分
# 2、如果要输入赛事ID参数，则必须输入同一种赛事ID，比如只能输入2003这种类型或者2003-2004这种类型
class ScheduleUpdateCmd < CmdParse::Command
  def initialize
    super('update', false)
    self.short_desc = "从最新的赛果数据中更新赛程数据"
    self.description = "从最新的赛果数据中更新赛程数据"
  end

  def execute(args)
    ScheduleCtrl.update(args)
  end
end

class ScheduleDPUCmd < CmdParse::Command
  def initialize
    super('dpu', false)
    self.short_desc = "下载赛程数据预处理、导入数据库"
    self.description = "下载赛程数据预、导入数据库"
  end

  def execute(args)
    ScheduleCtrl.dpu(args)
  end
end
