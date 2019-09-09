Sidekiq.configure_server do |config|
  if ENV["REDIS_URL"] == "redis-secret-stag"
    url = "redis://:UD4ywLh7V13N4bNe@redis-persistent-x77cx:6379")
    config.redis = { url: url, network_timeout: 5}
  else
    config.redis = { url: ENV['REDIS_URL'], network_timeout: 5}
  end
end

Sidekiq.configure_client do |config|
  if ENV["REDIS_URL"] == "redis-secret-stag"
    url = "redis://:UD4ywLh7V13N4bNe@redis-persistent-x77cx:6379")
    config.redis = { url: url, size: 3 }
  else
    config.redis = { url: ENV['REDIS_URL'], size: 3 }
  end
end

# https://github.com/mperham/sidekiq/wiki/Advanced-Options
Sidekiq.default_worker_options = {
  'backtrace' => true, # save backtrace, for easy debug, nice
  'retry' => 3 # max retry
}
