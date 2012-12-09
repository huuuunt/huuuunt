
require 'iconv'

module Huuuunt
  module Common
    def self.included(base)
      base.extend Huuuunt::Common
    end

    # 为避免赛果数据为空时，使用0会带来的误解，改用"-1"表示为空的赛果
    def gooooal(goal)
      return -1 if goal==nil || goal.size==0
      return goal.strip
    end

    def full_matchno(matchno)
      len = matchno.to_s.length
      if len<1 || len>4
        return
      end
      full_matchno = ""
      (4-len).times { full_matchno += "0" }
      return full_matchno + matchno.to_s
    end

    def full_teamno(teamno)
      len = teamno.to_s.length
      if len<1 || len>5
        return
      end
      full_teamno = ""
      (5-len).times { full_teamno += "0" }
      return full_teamno + teamno.to_s
    end

    def create_matchinfono(date, matchno, team1no, team2no)
      "#{date.split('-').join}#{full_matchno(matchno)}#{full_teamno(team1no)}#{full_teamno(team2no)}"
    end

    def gbk2utf8(gbk)
      return nil if gbk==nil || gbk.length==0
      return Iconv.iconv("UTF-8", "GBK", gbk.strip)[0]
    end

    def utf82gbk(utf8)
      return nil if utf8==nil || utf8.length==0
      return Iconv.iconv("GBK", "UTF-8", utf8.strip)[0]
    end

    # Example: finrate (0.75)
    def calc_asia_result(finrate, direction, goal1, goal2)
      result = (goal1 - goal2) * 4 - ((finrate * 4).to_i)*direction
      #puts "result = #{result} "
      result = result.to_i
      if result <= -2
        return -2
      elsif result == -1
        return -1
      elsif result == 0
        return 0
      elsif result == 1
        return 1
      elsif result >= 2
        return 2
      end
    end



  end
end
