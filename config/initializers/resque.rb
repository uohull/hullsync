Resque.redis = "redis://188.166.155.21:6379"
Resque.logger = Logger.new(Rails.root.join('log', "#{Rails.env}_resque.log"))
