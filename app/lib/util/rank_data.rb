
require 'rubygems'
require 'hpricot'

require 'mysql/match'
require 'mysql/team'
require 'mysql/rank'
require 'mysql/schedule'

require 'util/common'

module Huuuunt
  module RankData

    include Huuuunt::Common

    def self.included(base)
      base.extend Huuuunt::RankData
    end

    # 输入的season只有一种格式，即2010，match_set是match_id的数组
    def calculate_rank_base(season, match_set)
      # 计算每个轮次后各球队的积分等数据
      calculate_rank_base_data(season, match_set)
    end # calculate_rank

    # 按照每个轮次计算各球队的排名
    def calculate_rank_history(season, match_set)
      # 
      calculate_rank_by_phase(season, match_set)
    end

    # 计算
    def calculate_rank_current(season, match_set)
      #
      calculate_rank_special(season, match_set)
    end

    def calculate_rank_base_data(season, match_set)
      match_set.each do |match_id|
        h_home = {}
        h_away = {}
        scores = {}

        # 初始化
        teams = Schedule.get_distinct_teams(season, match_id)
        teams.each do |teamno|
          team_id = teamno.team1no.to_i
          # puts team_id
          # 初始化数值标识：积分、进球数、净球数、失球数、赢场次数、平场次数、输场次数、已赛次数、轮次
          h_home[team_id] = { 'score' => 0, 'wingoal' => 0, 'goal' => 0, 'lossgoal' => 0, 'wincnt' => 0, 'deucecnt' => 0, 'losscnt' => 0, 'matchcnt' => 0, 'phase' => 0 }
          h_away[team_id] = { 'score' => 0, 'wingoal' => 0, 'goal' => 0, 'lossgoal' => 0, 'wincnt' => 0, 'deucecnt' => 0, 'losscnt' => 0, 'matchcnt' => 0, 'phase' => 0 }
          scores[team_id] = { 'score' => 0, 'wingoal' => 0, 'goal' => 0, 'lossgoal' => 0, 'wincnt' => 0, 'deucecnt' => 0, 'losscnt' => 0, 'matchcnt' => 0, 'phase' => 0 }
        end

        # 从赛程中读取出已经完成的比赛
        matches_arr = Schedule.get_finished_matches_by_matchdt_asc(season, match_id)

        # 从赛事数据中分别统计出主场球队的情况和客场球队的情况
        matches_arr.each do |item|
          team1no = item.team1no.to_i
          team2no = item.team2no.to_i
          goal1 = item.goal1.to_i
          goal2 = item.goal2.to_i
          
          phase = item.phase.to_i

          #result1 = 0
          #result2 = 0
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
            h_home[team1no]['score'] = h_home[team1no]['score'] + result1         # 积分
            h_home[team1no]['wingoal'] = h_home[team1no]['wingoal'] + goal1           # 进球数
            h_home[team1no]['goal'] = h_home[team1no]['goal'] + goal1-goal2     # 净球数
            h_home[team1no]['lossgoal'] = h_home[team1no]['lossgoal'] + goal2           # 失球数
            h_home[team1no]['wincnt'] = h_home[team1no]['wincnt'] + wincnt1         # 赢场次数
            h_home[team1no]['deucecnt'] = h_home[team1no]['deucecnt'] + deucecnt1       # 平场次数
            h_home[team1no]['losscnt'] = h_home[team1no]['losscnt'] + losscnt1        # 输场次数
            h_home[team1no]['matchcnt'] = h_home[team1no]['matchcnt'] + 1               # 已赛场次
          else
            puts "#{team1no} has error!"
            #h_home[team1no] = [result1, goal1, goal1-goal2, wincnt1, deucecnt1, losscnt1, 1]
          end

          # 统计客场球队数据
          if h_away.has_key?(team2no)
            h_away[team2no]['score'] = h_away[team2no]['score'] + result2         # 积分
            h_away[team2no]['wingoal'] = h_away[team2no]['wingoal'] + goal2           # 进球数
            h_away[team2no]['goal'] = h_away[team2no]['goal'] + goal2-goal1     # 净球数
            h_away[team2no]['lossgoal'] = h_away[team2no]['lossgoal'] + goal1           # 失球数
            h_away[team2no]['wincnt'] = h_away[team2no]['wincnt'] + wincnt2         # 赢场次数
            h_away[team2no]['deucecnt'] = h_away[team2no]['deucecnt'] + deucecnt2       # 平场次数
            h_away[team2no]['losscnt'] = h_away[team2no]['losscnt'] + losscnt2        # 输场次数
            h_away[team2no]['matchcnt'] = h_away[team2no]['matchcnt'] + 1               # 已赛场次
          else
            puts "#{team2no} has error!"
            #h_away[team2no] = [result2, goal2, goal2-goal1, wincnt2, deucecnt2, losscnt2, 1]
          end

          # 将主场数据加入总场次统计数据中
          if scores.has_key?(team1no)
            scores[team1no]['score'] = scores[team1no]['score'] + result1
            scores[team1no]['wingoal'] = scores[team1no]['wingoal'] + goal1
            scores[team1no]['goal'] = scores[team1no]['goal'] + goal1-goal2
            scores[team1no]['lossgoal'] = scores[team1no]['lossgoal'] + goal2
            scores[team1no]['wincnt'] = scores[team1no]['wincnt'] + wincnt1
            scores[team1no]['deucecnt'] = scores[team1no]['deucecnt'] + deucecnt1
            scores[team1no]['losscnt'] = scores[team1no]['losscnt'] + losscnt1
            scores[team1no]['matchcnt'] = scores[team1no]['matchcnt'] + 1
            #puts "#{scores[team1no]['score']}, #{result1}" if team1no==1
          end

          # 将客场数据加入总场次统计数据中
          if scores.has_key?(team2no)
            scores[team2no]['score'] = scores[team2no]['score'] + result2
            scores[team2no]['wingoal'] = scores[team2no]['wingoal'] + goal2
            scores[team2no]['goal'] = scores[team2no]['goal'] + goal2-goal1
            scores[team2no]['lossgoal'] = scores[team2no]['lossgoal'] + goal1
            scores[team2no]['wincnt'] = scores[team2no]['wincnt'] + wincnt2
            scores[team2no]['deucecnt'] = scores[team2no]['deucecnt'] + deucecnt2
            scores[team2no]['losscnt'] = scores[team2no]['losscnt'] + losscnt2
            scores[team2no]['matchcnt'] = scores[team2no]['matchcnt'] + 1
            #puts "#{scores[team2no]['score']}, #{result2}" if team2no==1
          end

          # 插入当前赛事后主队和客队的rank数据
          Rank.insert_or_update_all(match_id, season, team1no, phase, item.matchdt,
            scores[team1no]['score'], scores[team1no]['wingoal'], scores[team1no]['goal'], scores[team1no]['lossgoal'], scores[team1no]['wincnt'], scores[team1no]['deucecnt'], scores[team1no]['losscnt'], scores[team1no]['matchcnt'],
            h_home[team1no]['score'], h_home[team1no]['wingoal'], h_home[team1no]['goal'], h_home[team1no]['lossgoal'], h_home[team1no]['wincnt'], h_home[team1no]['deucecnt'], h_home[team1no]['losscnt'], h_home[team1no]['matchcnt'],
            h_away[team1no]['score'], h_away[team1no]['wingoal'], h_away[team1no]['goal'], h_away[team1no]['lossgoal'], h_away[team1no]['wincnt'], h_away[team1no]['deucecnt'], h_away[team1no]['losscnt'], h_away[team1no]['matchcnt']
          )
          Rank.insert_or_update_all(match_id, season, team2no, phase,item.matchdt,
            scores[team2no]['score'], scores[team2no]['wingoal'], scores[team2no]['goal'], scores[team2no]['lossgoal'], scores[team2no]['wincnt'], scores[team2no]['deucecnt'], scores[team2no]['losscnt'], scores[team2no]['matchcnt'],
            h_home[team2no]['score'], h_home[team2no]['wingoal'], h_home[team2no]['goal'], h_home[team2no]['lossgoal'], h_home[team2no]['wincnt'], h_home[team2no]['deucecnt'], h_home[team2no]['losscnt'], h_home[team2no]['matchcnt'],
            h_away[team2no]['score'], h_away[team2no]['wingoal'], h_away[team2no]['goal'], h_away[team2no]['lossgoal'], h_away[team2no]['wincnt'], h_away[team2no]['deucecnt'], h_away[team2no]['losscnt'], h_away[team2no]['matchcnt']
          )

        end # matches_arr.each do |item|
      end # match_set.each
    end
    
    def calculate_rank_by_phase(season, match_set)
      match_set.each do |match_id|

        teams = Match.get_teams(match_id).to_i
        
        matches = Rank.calculate_rank_of_all_home_away(match_id, season)

        #puts "#{match_id}, #{season}, #{matches['all'].size}, #{teams} ranks [all]  base data error!" if matches['all'].size % teams != 0
        #puts "#{match_id}, #{season}, #{matches['all'].size}, #{teams} ranks [home] base data error!" if matches['home'].size % teams != 0
        #puts "#{match_id}, #{season}, #{matches['all'].size}, #{teams} ranks [away] base data error!" if matches['away'].size % teams != 0

        rank = 0
        current_phase = 1
        matches['all'].each do |item|
          if current_phase != item.phase
            rank = 1
            current_phase = item.phase
          else
            rank += 1
          end

          item.rank = rank
          item.save
        end

        rankH = 0
        current_phase = 1
        matches['home'].each do |item|
          if current_phase != item.phase
            rankH = 1
            current_phase = item.phase
          else
            rankH += 1
          end

          item.rankH = rankH
          item.save
        end

        rankA = 0
        current_phase = 1
        matches['away'].each do |item|
          if current_phase != item.phase
            rankA = 1
            current_phase = item.phase
          else
            rankA += 1
          end

          item.rankA = rankA
          item.save
        end
      end
      
    end

  end # RankData
end # Huuuunt

