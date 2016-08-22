class NotificationsController < ApplicationController


  def index
    logger.info("---------------------------")
    logger.info("BOX NOTIFICATION RECEIVED")
    logger.info("Event:\t#{params[:event_type]}")
    logger.info("Item Name:\t#{params[:item_name]}")
    logger.info("Item Type:\t#{params[:item_type]}")
    logger.info("Item Id:\t#{params[:item_id]}")
    Resque.enqueue(WatchProcessorJob, params)
  end
end
