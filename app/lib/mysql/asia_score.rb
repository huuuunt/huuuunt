
require 'mysql/driver'

class AsiaScore < ActiveRecord::Base
  def self.insert_or_update_all(match_id, season, teamno,
                                wincnt, deucecnt, losscnt, matchcnt, ratecnt,
                                wincntH, deucecntH, losscntH, matchcntH, ratecntH,
                                wincntA, deucecntA, losscntA, matchcntA, ratecntA,
                                wincnt6, deucecnt6, losscnt6, matchcnt6, ratecnt6,
                                history6, history6H, history6A)

    score_exist = where("matchno=#{match_id} and season=#{season} and teamno=#{teamno}")

    # insert
    if score_exist.size == 0
      new_score = AsiaScore.new
      
      new_score.matchno = match_id
      new_score.season = season
      new_score.teamno = teamno
      # 总积分
      new_score.wincnt = wincnt
      new_score.deucecnt = deucecnt
      new_score.losscnt = losscnt
      new_score.matchcnt = matchcnt
      new_score.ratecnt = ratecnt
      # 主场积分
      new_score.wincntH = wincntH
      new_score.deucecntH = deucecntH
      new_score.losscntH = losscntH
      new_score.matchcntH = matchcntH
      new_score.ratecntH = ratecntH
      # 客场积分
      new_score.wincntA = wincntA
      new_score.deucecntA = deucecntA
      new_score.losscntA = losscntA
      new_score.matchcntA = matchcntA
      new_score.ratecntA = ratecntA
      # 近6场积分
      new_score.wincnt6 = wincnt6
      new_score.deucecnt6 = deucecnt6
      new_score.losscnt6 = losscnt6
      new_score.matchcnt6 = matchcnt6
      new_score.ratecnt6 = ratecnt6

      # 近6场历史记录显示
      new_score.history6 = history6
      new_score.history6H = history6H
      new_score.history6A = history6A

      new_score.save
    # update
    elsif score_exist.size == 1
      score_exist = score_exist.first
      # 总积分
      score_exist.wincnt = wincnt
      score_exist.deucecnt = deucecnt
      score_exist.losscnt = losscnt
      score_exist.matchcnt = matchcnt
      score_exist.ratecnt = ratecnt
      # 主场积分
      score_exist.wincntH = wincntH
      score_exist.deucecntH = deucecntH
      score_exist.losscntH = losscntH
      score_exist.matchcntH = matchcntH
      score_exist.ratecntH = ratecntH
      # 客场积分
      score_exist.wincntA = wincntA
      score_exist.deucecntA = deucecntA
      score_exist.losscntA = losscntA
      score_exist.matchcntA = matchcntA
      score_exist.ratecntA = ratecntA
      # 近6场积分
      score_exist.wincnt6 = wincnt6
      score_exist.deucecnt6 = deucecnt6
      score_exist.losscnt6 = losscnt6
      score_exist.matchcnt6 = matchcnt6
      score_exist.ratecnt6 = ratecnt6

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


end