# encoding: utf-8
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

    def create_matchinfono2(datetime, matchno, team1no, team2no)
      date = datetime.split[0]
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
    def calc_asia_result(finrate, goal1, goal2)
      return nil unless finrate
      result = (goal1.to_i - goal2.to_i) * 4 - (finrate.to_i)
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

    def gooooal_asia_odd_direction(finrate)
      return nil unless finrate
      return -1 if finrate.include?("受让")
      return 1
    end

    def gooooal_asia_odd(finrate)
      return nil unless finrate
      
      arr_finrate = {
        "受让四球"        => -16,
        "受让三球半/四球"  => -15,
        "受让三球半"      => -14,
        "受让三球/三球半"  => -13,
        "受让三球"        => -12,
        "受让两球半/三球"   => -11,
        "受让两球半"       => -10,
        "受让两球/两球半"   => -9,
        "受让两球"        => -8,
        "受让球半/两球"    => -7,
        "受让球半"         => -6,
        "受让一球/球半"     => -5,
        "受让一球"        => -4,
        "受让半球/一球"    => -3,
        "受让半球"         => -2,
        "受让平手/半球"     => -1,
        "受让平手"          => 0,

        "四球"        => 16,
        "三球半/四球"  => 15,
        "三球半"      => 14,
        "三球/三球半"  => 13,
        "三球"        => 12,
        "两球半/三球"   => 11,
        "两球半"       => 10,
        "两球/两球半"   => 9,
        "两球"        => 8,
        "球半/两球"    => 7,
        "球半"         => 6,
        "一球/球半"     => 5,
        "一球"        => 4,
        "半球/一球"    => 3,
        "半球"         => 2,
        "平手/半球"     => 1,
        "平手"          => 0
      }
      return arr_finrate[finrate.strip]
    end
    


  end
end
