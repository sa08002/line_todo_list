class LineBotController < ApplicationController
  protect_from_forgery with: :null_session

  def callback
  end
end
