# 从Gooooal获取的赛程数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/schedule_gooooal_ctrl'

class ScheduleGooooalCmd < CmdParse::Command
  def initialize
    super('schedule-gooooal', true)
    self.short_desc = "赛程数据处理程序"
    self.description = "赛程数据处理程序"
  end
end

class ScheduleGooooalPreprocessCmd < CmdParse::Command
    def initialize
    super('preprocess', false)
    self.short_desc = "检查赛程数据是否存在不能识别球队信息"
    self.description = "检查赛程数据是否存在不能识别球队信息"
  end

  def execute(args)
    ScheduleGooooalCtrl.preprocess(args)
  end
end

class ScheduleGooooalImportCmd < CmdParse::Command
  def initialize
    super('import', false)
    self.short_desc = "将预处理好的赛程数据导入数据库"
    self.description = "将预处理好的赛程数据导入数据库"
  end

  def execute(args)
    ScheduleGooooalCtrl.import(args)
  end
end


