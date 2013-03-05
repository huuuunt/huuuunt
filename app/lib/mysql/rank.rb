
require 'mysql/driver'

class Rank < ActiveRecord::Base

  def self.insert_or_update_all(match_id, season, teamno, phase, matchdt,
                                score, wingoal, goal, lossgoal, wincnt, deucecnt, losscnt, matchcnt,
                                scoreH, wingoalH, goalH, lossgoalH, wincntH, deucecntH, losscntH, matchcntH,
                                scoreA, wingoalA, goalA, lossgoalA, wincntA, deucecntA, losscntA, matchcntA )

    rank_exist = where("matchno=#{match_id} and season=#{season} and teamno=#{teamno} and phase=#{phase}")

    # insert
    if rank_exist.size == 0
      new_rank = Rank.new

      new_rank.matchno = match_id
      new_rank.season = season
      new_rank.teamno = teamno
      new_rank.phase = phase
      new_rank.matchdt = matchdt
      # 总积分
      new_rank.score = score
      new_rank.wingoal = wingoal
      new_rank.goal = goal
      new_rank.lossgoal = lossgoal
      new_rank.wincnt = wincnt
      new_rank.deucecnt = deucecnt
      new_rank.losscnt = losscnt
      new_rank.matchcnt = matchcnt
      # 主场积分
      new_rank.scoreH = scoreH
      new_rank.wingoalH = wingoalH
      new_rank.goalH = goalH
      new_rank.lossgoalH = lossgoalH
      new_rank.wincntH = wincntH
      new_rank.deucecntH = deucecntH
      new_rank.losscntH = losscntH
      new_rank.matchcntH = matchcntH
      # 客场积分
      new_rank.scoreA = scoreA
      new_rank.wingoalA = wingoalA
      new_rank.goalA = goalA
      new_rank.lossgoalA = lossgoalA
      new_rank.wincntA = wincntA
      new_rank.deucecntA = deucecntA
      new_rank.losscntA = losscntA
      new_rank.matchcntA = matchcntA

      new_rank.save
    # update
    elsif rank_exist.size == 1
      rank_exist = rank_exist.first

      rank_exist.phase = phase
      rank_exist.matchdt = matchdt
      # 总积分
      rank_exist.score = score
      rank_exist.wingoal = wingoal
      rank_exist.goal = goal
      rank_exist.lossgoal = lossgoal
      rank_exist.wincnt = wincnt
      rank_exist.deucecnt = deucecnt
      rank_exist.losscnt = losscnt
      rank_exist.matchcnt = matchcnt
      # 主场积分
      rank_exist.scoreH = scoreH
      rank_exist.wingoalH = wingoalH
      rank_exist.goalH = goalH
      rank_exist.lossgoalH = lossgoalH
      rank_exist.wincntH = wincntH
      rank_exist.deucecntH = deucecntH
      rank_exist.losscntH = losscntH
      rank_exist.matchcntH = matchcntH
      # 客场积分
      rank_exist.scoreA = scoreA
      rank_exist.wingoalA = wingoalA
      rank_exist.goalA = goalA
      rank_exist.lossgoalA = lossgoalA
      rank_exist.wincntA = wincntA
      rank_exist.deucecntA = deucecntA
      rank_exist.losscntA = losscntA
      rank_exist.matchcntA = matchcntA

      rank_exist.save
    else
      puts "score(matchno=#{match_id} and season=#{season} and teamno=#{teamno} and phase=#{phase}) error!"
    end

  end

  # 计算总榜积分排名、主场积分排名、客场积分排名
  def self.calculate_rank_of_all_home_away(match_id, season)
    data = {}
    data['all'] = calculate_rank_by_all_data(match_id, season)
    data['home'] = calculate_rank_by_home_data(match_id, season)
    data['away'] = calculate_rank_by_away_data(match_id, season)
    data
  end

  # 根据积分总榜计算排名
  def self.calculate_rank_by_all_data(match_id, season)
    find_by_sql("select * from #{$tab['rank']}
                  where matchno=#{match_id} and season='#{season}'
                  order by phase, score desc, goal desc, wingoal desc, lossgoal;")
  end

  # 根据主场积分计算排名
  def self.calculate_rank_by_home_data(match_id, season)
    find_by_sql("select * from #{$tab['rank']}
                  where matchno=#{match_id} and season='#{season}'
                  order by phase, scoreH desc, goalH desc, wingoalH desc, lossgoalH;")
  end

  # 根据客场积分计算排名
  def self.calculate_rank_by_away_data(match_id, season)
    find_by_sql("select * from #{$tab['rank']}
                  where matchno=#{match_id} and season='#{season}'
                  order by phase, scoreA desc, goalA desc, wingoalA desc, lossgoalA;")
  end
  

end