if ENV["REDIS_URL"] == "redis-secret-stag"
  $redis = Redis.new(:url => "redis://:UD4ywLh7V13N4bNe@redis-persistent-x77cx:6379/0") 
else
  $redis = Redis.new(:url => ENV["REDIS_URL"]) #default
end