
require 'rubygems'
require 'hpricot'

require 'mysql/match'
require 'mysql/team'
require 'mysql/score'
require 'mysql/asia_score'
require 'mysql/schedule'

require 'util/common'

module Huuuunt
  module ScoreData

    include Huuuunt::Common

    def self.included(base)
      base.extend Huuuunt::ScoreData
    end

    # 输入的season只有一种格式，即2010，match_set是match_id的数组
    def calculate_score(season, match_set)
      match_set.each do |match_id|
        h_home = {}
        h_away = {}
        scores = {}
        scores6 = {}

        # 初始化
        teams = Schedule.get_distinct_teams(season, match_id)
        teams.each do |teamno|
          team_id = teamno.team1no.to_i
          # puts team_id
          # 初始化数值标识：积分、进球数、净球数、赢场次数、平场次数、输场次数、已赛次数、输赢历史、失球数
          h_home[team_id] = [0,0,0,0,0,0,0,"",0]
          h_away[team_id] = [0,0,0,0,0,0,0,"",0]
          scores[team_id] = [0,0,0,0,0,0,0,"",0]
          scores6[team_id] = [0,0,0,0,0,0,0,"",0]
        end

        # 从赛程中读取出已经完成的比赛
        matches_arr = Schedule.get_finished_matches(season, match_id)

        # 从赛事数据中分别统计出主场球队的情况和客场球队的情况
        matches_arr.each do |item|
          team1no = item.team1no.to_i
          team2no = item.team2no.to_i
          goal1 = item.goal1.to_i
          goal2 = item.goal2.to_i

          result1 = 0
          result2 = 0
          wincnt1 = 0
          wincnt2 = 0
          deucecnt1 = 0
          deucecnt2 = 0
          losscnt1 = 0
          losscnt2 = 0
          if goal1 > goal2
            result1 = 3
            result2 = 0
            wincnt1 = 1
            losscnt2 = 1
          elsif goal1 == goal2
            result1 = 1
            result2 = 1
            deucecnt1 = 1
            deucecnt2  =1
          else
            result1 = 0
            result2 = 3
            losscnt1 = 1
            wincnt2 = 1
          end

          if team1no==1 or team2no==1
            #puts "#{result1}, #{result2}, #{wincnt1}, #{wincnt2}, #{deucecnt1}, #{deucecnt2}, #{losscnt1}, #{losscnt2}"
          end

          # 统计主场球队数据
          if h_home.has_key?(team1no)
            h_home[team1no][0] = h_home[team1no][0] + result1         # 积分
            h_home[team1no][1] = h_home[team1no][1] + goal1           # 进球数
            h_home[team1no][2] = h_home[team1no][2] + goal1-goal2     # 净球数
            h_home[team1no][3] = h_home[team1no][3] + wincnt1         # 赢场次数
            h_home[team1no][4] = h_home[team1no][4] + deucecnt1       # 平场次数
            h_home[team1no][5] = h_home[team1no][5] + losscnt1        # 输场次数
            h_home[team1no][6] = h_home[team1no][6] + 1               # 已赛场次
            h_home[team1no][7] = h_home[team1no][7] + "#{result1}"    # 输赢历史
            h_home[team1no][8] = h_home[team1no][8] + goal2           # 失球数
          else
            puts "#{team1no} has error!"
            #h_home[team1no] = [result1, goal1, goal1-goal2, wincnt1, deucecnt1, losscnt1, 1]
          end
          # 统计客场球队数据
          if h_away.has_key?(team2no)
            h_away[team2no][0] = h_away[team2no][0] + result2
            h_away[team2no][1] = h_away[team2no][1] + goal2
            h_away[team2no][2] = h_away[team2no][2] + goal2-goal1
            h_away[team2no][3] = h_away[team2no][3] + wincnt2
            h_away[team2no][4] = h_away[team2no][4] + deucecnt2
            h_away[team2no][5] = h_away[team2no][5] + losscnt2
            h_away[team2no][6] = h_away[team2no][6] + 1
            h_away[team2no][7] = h_away[team2no][7] + "#{result2}"
            h_away[team2no][8] = h_away[team2no][8] + goal1
          else
            puts "#{team2no} has error!"
            #h_away[team2no] = [result2, goal2, goal2-goal1, wincnt2, deucecnt2, losscnt2, 1]
          end
          # 将主场数据加入总场次统计数据中
          if scores.has_key?(team1no)
            scores[team1no][0] = scores[team1no][0] + result1
            scores[team1no][1] = scores[team1no][1] + goal1
            scores[team1no][2] = scores[team1no][2] + goal1-goal2
            scores[team1no][3] = scores[team1no][3] + wincnt1
            scores[team1no][4] = scores[team1no][4] + deucecnt1
            scores[team1no][5] = scores[team1no][5] + losscnt1
            scores[team1no][6] = scores[team1no][6] + 1
            scores[team1no][7] = scores[team1no][7] + "#{result1}"
            scores[team1no][8] = scores[team1no][8] + goal2

            #puts "#{scores[team1no][0]}, #{result1}" if team1no==1
          end
          # 将客场数据加入总场次统计数据中
          if scores.has_key?(team2no)
            scores[team2no][0] = scores[team2no][0] + result2
            scores[team2no][1] = scores[team2no][1] + goal2
            scores[team2no][2] = scores[team2no][2] + goal2-goal1
            scores[team2no][3] = scores[team2no][3] + wincnt2
            scores[team2no][4] = scores[team2no][4] + deucecnt2
            scores[team2no][5] = scores[team2no][5] + losscnt2
            scores[team2no][6] = scores[team2no][6] + 1
            scores[team2no][7] = scores[team2no][7] + "#{result2}"
            scores[team2no][8] = scores[team2no][8] + goal1
            
            #puts "#{scores[team2no][0]}, #{result2}" if team2no==1
          end
          
          # 因为读取轮次赛事时，按照matchdt降序排列，所以近6轮的数据只需要在场次达到6场时记录一次即可
          # 总积分近6场计算，如果主场球队总场次达到6场
          if scores[team1no][6] == 6
            scores6[team1no] = [
                  scores[team1no][0],scores[team1no][1],scores[team1no][2],
                  scores[team1no][3],scores[team1no][4],scores[team1no][5],
                  6, scores[team1no][7], scores[team1no][8]
            ]
          end
          # 如果客场球队总场次达到6场
          if scores[team2no][6] == 6
            scores6[team2no] = [
                  scores[team2no][0],scores[team2no][1],scores[team2no][2],
                  scores[team2no][3],scores[team2no][4],scores[team2no][5],
                  6, scores[team2no][7], scores[team2no][8]
            ]
          end
        end # matches_arr.each do |item|

        # 如果本赛季已赛场次都已经统计完成后，最近6场统计数据仍然为空，则认为总场次未满6场，因此直接从总场次中获取数据
        scores6.each_key do |key|
          if scores6[key][6] == 0
            scores6[key][0] = scores[key][0]
            scores6[key][1] = scores[key][1]
            scores6[key][2] = scores[key][2]
            scores6[key][3] = scores[key][3]
            scores6[key][4] = scores[key][4]
            scores6[key][5] = scores[key][5]
            scores6[key][6] = scores[key][6]
            scores6[key][7] = scores[key][7]
            scores6[key][8] = scores[key][8]
          end
        end

        # 以上积分相关数据统计完成，插入或更新积分榜数据
        scores.each_key do |key|
          puts "#{key}, #{scores[key].join('-')}"
          
          Score.insert_or_update_all(match_id, season, key,
            scores[key][0], scores[key][1], scores[key][2], scores[key][3], scores[key][4], scores[key][5], scores[key][6], scores[key][8],
            h_home[key][0], h_home[key][1], h_home[key][2], h_home[key][3], h_home[key][4], h_home[key][5], h_home[key][6], h_home[key][8],
            h_away[key][0], h_away[key][1], h_away[key][2], h_away[key][3], h_away[key][4], h_away[key][5], h_away[key][6], h_away[key][8],
            scores6[key][0], scores6[key][1], scores6[key][2], scores6[key][3], scores6[key][4], scores6[key][5], scores6[key][6], scores6[key][8],
            scores6[key][7], h_home[key][7].slice(0,6), h_away[key][7].slice(0,6)
          )
        end

      end
    end

    def check_score(season, match_set)
      match_set.each do |match_id|
        puts "start #{match_id}, #{Match.get_match_name_by_id(match_id)}"
        score_db = {}
        score_db[0] = {}
        score_db[1] = {}
        score_db[2] = {}
        score_db[3] = {}

        score_gooooal = {}
        score_gooooal[0] = {}
        score_gooooal[1] = {}
        score_gooooal[2] = {}
        score_gooooal[3] = {}

        # 初始化数据库中的积分数据
        score_db_set = Score.get_score_by_match_season(season, match_id)
        score_db_set.each do |item|
          #puts "#{item.teamno.to_i}, #{Team.get_team_name_by_id(item.teamno.to_i)}"
          score_db[0][item.teamno.to_i] = [item.score.to_i-item.point.to_i, item.matchcnt.to_i, item.wincnt.to_i, item.deucecnt.to_i, item.losscnt.to_i, item.wingoal.to_i, item.lossgoal.to_i, item.goal.to_i]
          score_db[1][item.teamno.to_i] = [item.scoreH.to_i, item.matchcntH.to_i, item.wincntH.to_i, item.deucecntH.to_i, item.losscntH.to_i, item.wingoalH.to_i, item.lossgoalH.to_i, item.goalH.to_i]
          score_db[2][item.teamno.to_i] = [item.scoreA.to_i, item.matchcntA.to_i, item.wincntA.to_i, item.deucecntA.to_i, item.losscntA.to_i, item.wingoalA.to_i, item.lossgoalA.to_i, item.goalA.to_i]
          score_db[3][item.teamno.to_i] = [item.score6.to_i, item.matchcnt6.to_i, item.wincnt6.to_i, item.deucecnt6.to_i, item.losscnt6.to_i, item.wingoal6.to_i, item.lossgoal6.to_i, item.goal6.to_i]
          #puts "#{item.teamno.to_i}, #{score_db[3][item.teamno.to_i].join("-")}"
        end

        # 读取并分析整理gooooal中的积分数据
        scores_url = "http://app.gooooal.com/competition.do?lid=#{Match.get_gooooal_match_id(match_id)}&sid=#{season}&pid=#{Match.get_gooooal_match_id_2(match_id)}&lang=tr"
        #scores_data = Net::HTTP::Proxy('192.168.13.19', 7777).get(URI.parse(scores_url))
        scores_data = Net::HTTP.get(URI.parse(scores_url))

        doc = Hpricot(scores_data)
        # 0,1,2,3分别代表总积分、主场积分、客场积分、近6场积分
        tables = [0,1,2,3]
        tables.each do |table_index|
          table = doc.search("#tb_data_#{table_index}")
          scores = table/'tr'
          count = 0
          scores.each do |score|
            count += 1
            # 第一行是字段名栏，需要忽略
            next if count==1
            content = ""
            details = score/'td'
            # 有时候会在其中插入一条通知信息，需要忽略
            next if details.size < 8
            
            team_name = details[1].inner_text
            team_id = Team.get_team_id_by_name(team_name)
            #puts "#{team_id}, #{team_name}"
            unless team_id
              puts "#{team_name}"  
              exit
            end

            d_score = details[2].inner_text.to_i
            d_matchcnt = details[3].inner_text.to_i
            d_wincnt = details[4].inner_text.to_i
            d_deucecnt = details[5].inner_text.to_i
            d_losscnt = details[6].inner_text.to_i
            d_wingoal = details[7].inner_text.to_i
            d_lossgoal = details[8].inner_text.to_i
            d_goal = details[9].inner_text.to_i

            score_gooooal[table_index][team_id.to_i] = [d_score, d_matchcnt, d_wincnt, d_deucecnt, d_losscnt, d_wingoal, d_lossgoal, d_goal]
            #puts "#{team_id}: #{score_gooooal[table_index][team_id.to_i].join(",")}"
          end # scores.each
          #puts " "
        end # tables.each

        # 比较数据库和gooooa的l数据
        tables.each do |index|
          score_db[index].each do |team_id, scores|
            #puts team_id
            #puts "+++++++++++++++++++++++++++++"
            scores.each_index do |s_index|
              #puts "#{index},#{team_id},#{s_index}"
              #puts "=== #{score_db[index][team_id][s_index]}"
              #puts "=== #{score_gooooal[index][team_id][s_index]}"
              unless score_db[index][team_id][s_index] == score_gooooal[index][team_id][s_index]
                puts "#{season},#{match_id},#{team_id},#{Team.get_team_name_by_id(team_id)} data is not correct."
              end
            end
            #puts "+++++++++++++++++++++++++++++"
          end

        end
      end
    end

    def calculate_asia_score(season, match_set)
      match_set.each do |match_id|
        h_home = {}
        h_away = {}
        scores = {}
        scores6 = {}

        # 初始化
        teams = Schedule.get_distinct_teams(season, match_id)
        teams.each do |teamno|
          team_id = teamno.team1no.to_i
          # puts team_id
          # 初始化数值标识：赢盘场次、走盘场次、输盘场次、已赛场次、开盘场次、近6场
          h_home[team_id] = [0,0,0,0,0,""]
          h_away[team_id] = [0,0,0,0,0,""]
          scores[team_id] = [0,0,0,0,0,""]
          scores6[team_id] = [0,0,0,0,0,""]
        end

        # 从赛程中读取出已经完成的比赛
        matches_arr = Schedule.get_finished_matches(season, match_id)

        # 从赛事数据中分别统计出主场球队的情况和客场球队的情况
        matches_arr.each do |item|
          team1no = item.team1no.to_i
          team2no = item.team2no.to_i
          result = item.result

          # 如果该赛事没有开盘，则仅对已赛场次+1
          unless result || result.size>0
            h_home[team1no][3] = h_home[team1no][3] + 1
            h_away[team2no][3] = h_away[team2no][3] + 1
            
            scores[team1no][3] = scores[team1no][3] + 1
            scores[team2no][3] = scores[team2no][3] + 1

            scores6[team1no][3] = scores6[team1no][3] + 1
            scores6[team2no][3] = scores6[team2no][3] + 1
            next
          end

          result1 = 0
          result2 = 0
          wincnt1 = 0
          wincnt2 = 0
          deucecnt1 = 0
          deucecnt2 = 0
          losscnt1 = 0
          losscnt2 = 0
          if result > 0
            wincnt1 = 1
            losscnt2 = 1
            result1 = 3
          elsif result == 0
            deucecnt1 = 1
            deucecnt2  =1
            result1 = 1
            result2 = 1
          else
            losscnt1 = 1
            wincnt2 = 1
            result2 = 3
          end

          if team1no==1 or team2no==1
            #puts "#{wincnt1}, #{wincnt2}, #{deucecnt1}, #{deucecnt2}, #{losscnt1}, #{losscnt2}"
          end

          # 统计主场球队数据
          if h_home.has_key?(team1no)
            h_home[team1no][0] = h_home[team1no][0] + wincnt1         # 赢场次数
            h_home[team1no][1] = h_home[team1no][1] + deucecnt1       # 平场次数
            h_home[team1no][2] = h_home[team1no][2] + losscnt1        # 输场次数
            h_home[team1no][3] = h_home[team1no][3] + 1               # 已赛场次
            h_home[team1no][4] = h_home[team1no][4] + 1               # 开盘场次
            h_home[team1no][5] = h_home[team1no][5] + "#{result1}"
          else
            puts "#{team1no} has error!"
            #h_home[team1no] = [result1, goal1, goal1-goal2, wincnt1, deucecnt1, losscnt1, 1]
          end
          # 统计客场球队数据
          if h_away.has_key?(team2no)
            h_away[team2no][0] = h_away[team2no][0] + wincnt2
            h_away[team2no][1] = h_away[team2no][1] + deucecnt2
            h_away[team2no][2] = h_away[team2no][2] + losscnt2
            h_away[team2no][3] = h_away[team2no][3] + 1
            h_away[team2no][4] = h_away[team2no][4] + 1
            h_away[team2no][5] = h_away[team2no][5] + "#{result2}"
          else
            puts "#{team2no} has error!"
            #h_away[team2no] = [result2, goal2, goal2-goal1, wincnt2, deucecnt2, losscnt2, 1]
          end
          # 将主场数据加入总场次统计数据中
          if scores.has_key?(team1no)
            scores[team1no][0] = scores[team1no][0] + wincnt1
            scores[team1no][1] = scores[team1no][1] + deucecnt1
            scores[team1no][2] = scores[team1no][2] + losscnt1
            scores[team1no][3] = scores[team1no][3] + 1
            scores[team1no][4] = scores[team1no][4] + 1
            scores[team1no][5] = scores[team1no][5] + "#{result1}"
          end
          # 将客场数据加入总场次统计数据中
          if scores.has_key?(team2no)
            scores[team2no][0] = scores[team2no][0] + wincnt2
            scores[team2no][1] = scores[team2no][1] + deucecnt2
            scores[team2no][2] = scores[team2no][2] + losscnt2
            scores[team2no][3] = scores[team2no][3] + 1
            scores[team2no][4] = scores[team2no][4] + 1
            scores[team2no][5] = scores[team2no][5] + "#{result2}"
          end

          # 因为读取轮次赛事时，按照matchdt降序排列，所以近6轮的数据只需要在场次达到6场时记录一次即可
          # 如果主场球队总场次达到6场
          if scores[team1no][3] == 6
            scores6[team1no] = [
                  scores[team1no][0],scores[team1no][1],scores[team1no][2],
                  scores[team1no][3],scores[team1no][4],scores[team1no][5]
            ]
          end
          # 如果客场球队总场次达到6场
          if scores[team2no][3] == 6
            scores6[team2no] = [
                  scores[team2no][0],scores[team2no][1],scores[team2no][2],
                  scores[team2no][3],scores[team2no][4],scores[team2no][5]
            ]
          end
        end # matches_arr.each do |item|

        # 如果本赛季已赛场次都已经统计完成后，最近6场统计数据仍然为空，则认为总场次未满6场，因此直接从总场次中获取数据
        scores6.each_key do |team_id|
          if scores6[team_id][4] == 0
            scores6[team_id][0] = scores[team_id][0]
            scores6[team_id][1] = scores[team_id][1]
            scores6[team_id][2] = scores[team_id][2]
            scores6[team_id][3] = scores[team_id][3]
            scores6[team_id][4] = scores[team_id][4]
            scores6[team_id][5] = scores[team_id][5]
          end
        end

        # 以上积分相关数据统计完成，插入或更新积分榜数据
        scores.each_key do |teamno|
          #puts "#{teamno}, #{scores[teamno].join('-')}"
          AsiaScore.insert_or_update_all(match_id, season, teamno,
            scores[teamno][0], scores[teamno][1], scores[teamno][2], scores[teamno][3], scores[teamno][4], 
            h_home[teamno][0], h_home[teamno][1], h_home[teamno][2], h_home[teamno][3], h_home[teamno][4], 
            h_away[teamno][0], h_away[teamno][1], h_away[teamno][2], h_away[teamno][3], h_away[teamno][4], 
            scores6[teamno][0], scores6[teamno][1], scores6[teamno][2], scores6[teamno][3], scores6[teamno][4],
            scores[teamno][5].slice(0,6), h_home[teamno][5].slice(0,6), h_away[teamno][5].slice(0,6)
          )
        end

      end
    end

    def check_asia_score(season, match_set)
      match_set.each do |match_id|
        score_db = {}
        score_db[0] = {}
        score_db[1] = {}
        score_db[2] = {}
        score_db[3] = {}

        score_gooooal = {}
        score_gooooal[0] = {}
        score_gooooal[1] = {}
        score_gooooal[2] = {}
        score_gooooal[3] = {}

        # 初始化数据库中的积分数据
        score_db_set = AsiaScore.get_score_by_match_season(season, match_id)
        score_db_set.each do |item|
          score_db[0][item.teamno.to_i] = [item.wincnt.to_i, item.deucecnt.to_i, item.losscnt.to_i]
          score_db[1][item.teamno.to_i] = [item.wincntH.to_i, item.deucecntH.to_i, item.losscntH.to_i]
          score_db[2][item.teamno.to_i] = [item.wincntA.to_i, item.deucecntA.to_i, item.losscntA.to_i]
          score_db[3][item.teamno.to_i] = [item.wincnt6.to_i, item.deucecnt6.to_i, item.losscnt6.to_i]
          #puts "#{item.teamno.to_i}, #{score_db[3][item.teamno.to_i].join("-")}"
        end

        # 读取并分析整理gooooal中的积分数据
        scores_url = "http://app.gooooal.com/odds.do?lid=#{Match.get_gooooal_match_id(match_id)}&sid=#{season}&pid=#{Match.get_gooooal_match_id_2(match_id)}&lang=tr"
        scores_data = Net::HTTP::Proxy('192.168.13.19', 7777).get(URI.parse(scores_url))
        #scores_htm = Net::HTTP.get(URI.parse(scores_url))

        doc = Hpricot(scores_data)
        sss = doc.search("tr#data_odds_fbStatTeam_0_0")

        # 0,1,2,3分别代表总积分、主场积分、客场积分、近6场积分
        tables = [0,1,2,3]
        tables.each do |table_index|
          scores = doc.search("tr#data_odds_fbStatTeam_0_#{table_index}")
          scores.each do |score|
            details = score/'td'

            team_name = details[1].inner_text.strip
            team_id = Team.get_team_id_by_name(team_name)
            unless team_id
              puts "#{team_name}"
              exit
            end

            d_wincnt = details[2].inner_text.to_i
            d_deucecnt = details[3].inner_text.to_i
            d_losscnt = details[4].inner_text.to_i

            score_gooooal[table_index][team_id.to_i] = [d_wincnt, d_deucecnt, d_losscnt]
            #puts "#{team_id}: #{score_gooooal[table_index][team_id.to_i].join(",")}"
          end # scores.each
          #puts " "
        end # tables.each

        # 比较数据库和gooooa的l数据
        tables.each do |index|
          score_db[index].each do |team_id, scores|
            #puts team_id
            #puts "+++++++++++++++++++++++++++++"
            scores.each_index do |s_index|
              #puts "(#{s_index}) : #{score_db[index][team_id][s_index]}, #{score_gooooal[index][team_id][s_index]}"
              unless score_db[index][team_id][s_index] == score_gooooal[index][team_id][s_index]
                puts "#{season},#{match_id},#{team_id} data is not correct."
              end
            end
            #puts "+++++++++++++++++++++++++++++"
          end

        end
      end
    end
  


  end
end

