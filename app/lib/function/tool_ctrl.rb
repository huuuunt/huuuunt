# 赛程数据导入程序

require 'rubygems'

require 'mysql/team'
require 'mysql/result'
require 'mysql/schedule'

class ToolCtrl

  def self.changeTeamNo
    change_table = [
        #[ 9523, 979 ],
        #[ 10006, 7000 ],
        #[ 9779, 596 ],
        #[ 9542, 1343 ],
        #[ 9532, 1333 ],
        #[ 4192, 1333 ],
        #[ 5356, 1333 ],
        #[ 9544, 1342 ],
        #[ 9654, 9569 ],
        #[ 9571, 3311 ],
        #[ 9586, 2819 ],
        #[ 9585, 9434 ],
        #[ 9539, 1480 ],
        #[ 9596, 7542 ],
        #[ 9560, 6137 ],
        #[ 9576, 5520 ],
        #[ 9599, 642 ],
        #[ 9590, 640 ],
        #[ 9575, 4384 ],
        #[ 9600, 10146 ],
        #[ 9589, 634 ],
        #[ 6350, 2045 ],
        #[ 9601, 8598],
        #[ 9611,  5910 ],
        #[ 11067, 9612],
        #[ 7000,  5650],
        #[ 11030, 9618],
        #[ 9619,  1497],
        #[ 9625,  5519],
        #[ 9626,  5500],
        #[ 9627,  5523]
    ]

    change_table.each do |item|
      Result.update_team_id(item[0], item[1])
      Schedule.update_team_id(item[0], item[1])
      Score.update_team_id(item[0], item[1])
      Rank.update_team_id(item[0], item[1])
    end
  end

end