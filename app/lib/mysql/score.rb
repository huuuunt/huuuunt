
require 'mysql/driver'

class Score < ActiveRecord::Base
  
  def self.insert_or_update_all(match_id, season, teamno,
                                score, wingoal, goal, wincnt, deucecnt, losscnt, matchcnt, lossgoal,
                                scoreH, wingoalH, goalH, wincntH, deucecntH, losscntH, matchcntH, lossgoalH,
                                scoreA, wingoalA, goalA, wincntA, deucecntA, losscntA, matchcntA, lossgoalA,
                                score6, wingoal6, goal6, wincnt6, deucecnt6, losscnt6, matchcnt6, lossgoal6,
                                history6, history6H, history6A)

    score_exist = where("matchno=#{match_id} and season=#{season} and teamno=#{teamno}")

    # insert
    if score_exist.size == 0
      new_score = Score.new
      
      new_score.matchno = match_id
      new_score.season = season
      new_score.teamno = teamno
      # 总积分
      new_score.score = score
      new_score.wingoal = wingoal
      new_score.goal = goal
      new_score.wincnt = wincnt
      new_score.deucecnt = deucecnt
      new_score.losscnt = losscnt
      new_score.matchcnt = matchcnt
      new_score.lossgoal = lossgoal
      # 主场积分
      new_score.scoreH = scoreH
      new_score.wingoalH = wingoalH
      new_score.goalH = goalH
      new_score.wincntH = wincntH
      new_score.deucecntH = deucecntH
      new_score.losscntH = losscntH
      new_score.matchcntH = matchcntH
      new_score.lossgoalH = lossgoalH
      # 客场积分
      new_score.scoreA = scoreA
      new_score.wingoalA = wingoalA
      new_score.goalA = goalA
      new_score.wincntA = wincntA
      new_score.deucecntA = deucecntA
      new_score.losscntA = losscntA
      new_score.matchcntA = matchcntA
      new_score.lossgoalA = lossgoalA
      # 近6场积分
      new_score.score6 = score6
      new_score.wingoal6 = wingoal6
      new_score.goal6 = goal6
      new_score.wincnt6 = wincnt6
      new_score.deucecnt6 = deucecnt6
      new_score.losscnt6 = losscnt6
      new_score.matchcnt6 = matchcnt6
      new_score.lossgoal6 = lossgoal6

      # 近6场历史记录显示
      new_score.history6 = history6
      new_score.history6H = history6H
      new_score.history6A = history6A

      new_score.save
    # update
    elsif score_exist.size == 1
      score_exist = score_exist.first
      # 总积分
      score_exist.score = score
      score_exist.wingoal = wingoal
      score_exist.goal = goal
      score_exist.wincnt = wincnt
      score_exist.deucecnt = deucecnt
      score_exist.losscnt = losscnt
      score_exist.matchcnt = matchcnt
      score_exist.lossgoal = lossgoal
      # 主场积分
      score_exist.scoreH = scoreH
      score_exist.wingoalH = wingoalH
      score_exist.goalH = goalH
      score_exist.wincntH = wincntH
      score_exist.deucecntH = deucecntH
      score_exist.losscntH = losscntH
      score_exist.matchcntH = matchcntH
      score_exist.lossgoalH = lossgoalH
      # 客场积分
      score_exist.scoreA = scoreA
      score_exist.wingoalA = wingoalA
      score_exist.goalA = goalA
      score_exist.wincntA = wincntA
      score_exist.deucecntA = deucecntA
      score_exist.losscntA = losscntA
      score_exist.matchcntA = matchcntA
      score_exist.lossgoalA = lossgoalA
      # 近6场积分
      score_exist.score6 = score6
      score_exist.wingoal6 = wingoal6
      score_exist.goal6 = goal6
      score_exist.wincnt6 = wincnt6
      score_exist.deucecnt6 = deucecnt6
      score_exist.losscnt6 = losscnt6
      score_exist.matchcnt6 = matchcnt6
      score_exist.lossgoal6 = lossgoal6

      # 近6场历史记录显示
      score_exist.history6 = history6
      score_exist.history6H = history6H
      score_exist.history6A = history6A

      score_exist.save
    else
      puts "score(matchno=#{match_id} and season=#{season} and teamno=#{teamno}) error!"
    end

  end

  def self.get_score_by_match_season(season, match_id)
    where("matchno=#{match_id} and season=#{season}")
  end

  def self.update_team_id(s_id, d_id)
    where("teamno = #{s_id}").each do |r|
      r.teamno = d_id
      r.save
    end
  end

end