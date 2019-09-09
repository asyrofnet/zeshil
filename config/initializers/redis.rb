if ENV["REDIS_URL"] == "redis-secret-stag"
  $redis = Redis.new(:url => "redis://:UD4ywLh7V13N4bNe@localhost:6379") 
else
  $redis = Redis.new(:url => ENV["REDIS_URL"]) #default
end