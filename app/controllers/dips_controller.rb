class DipsController < ApplicationController

  def index
    logger.info("---------------------------")
    logger.info("DIP NOTIFICATION RECEIVED")
    logger.info(params)

    render json:{'note': "DIP Notification Received", 'params': params}

    #logger.info("Event:\t#{params[:event_type]}")
    #logger.info("Item Name:\t#{params[:item_name]}")
    #logger.info("Item Type:\t#{params[:item_type]}")
    #logger.info("Item Id:\t#{params[:item_id]}")

  end
end
