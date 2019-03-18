Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'], network_timeout: 5}
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], size: 3 }
end

# https://github.com/mperham/sidekiq/wiki/Advanced-Options
Sidekiq.default_worker_options = {
  'backtrace' => true, # save backtrace, for easy debug
  'retry' => 3 # max retry
}
