class RealtimeWorkerMatch
  
 @queue = :realtime_queue
 
 def self.perform(matchs)
   matchs.each { | match | puts match[1] }
 end
 
end