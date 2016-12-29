Resque.redis = "redis://localhost:6379"
Resque.logger = Logger.new(Rails.root.join('log', "#{Rails.env}_resque.log"))
