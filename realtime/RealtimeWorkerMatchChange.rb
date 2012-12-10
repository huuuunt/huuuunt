class RealtimeWorkerMatchChange
  
 @queue = :realtime_queue
 
 def self.perform(matchChgs)
   matchChgs.each { | matchChg | puts matchChg[1] }
 end
 
end