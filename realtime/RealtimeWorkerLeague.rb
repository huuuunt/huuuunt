class RealtimeWorkerLeague
  
 @queue = :realtime_queue
 
 def self.perform(leagues)
   leagues.each { | league | puts league[1] }
 end
 
end