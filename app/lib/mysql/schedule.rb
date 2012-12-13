
class Schedule < ActiveRecord::Base
  def self.schedule_exist?(new_season, match_id, phase_id, team1_id, team2_id)
    where("matchyear=:season AND phase=:phase_id AND matchno=:match_id AND team1no=:team1_id AND team2no=:team2_id",
          { :season => new_season, :phase_id => phase_id, :match_id => match_id, :team1_id => team1_id, :team2_id => team2_id}).size > 0
  end
end