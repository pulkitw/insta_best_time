class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  around_filter :wrap_in_transaction
  # before_filter :require_login
  before_filter :set_current_user
  after_filter :clear_current_user

  CLIENT_ID= "80cbc0949f3f48788f98be2074177a80"
  CLIENT_SECRET = "71cd7401726c43179ff9f4b3a5252116"

  Instagram.configure do |config|
    config.client_id = CLIENT_ID
    config.client_secret = CLIENT_SECRET
  end


  def require_login
    redirect_to user_sign_in_path unless session[:current_account_id].present? || params[:action] == 'sign_in'
  end

  def set_current_user
    if session[:current_user_id]
      User.current_user = @current_user = User.includes(:accounts).find_by_id(session[:current_user_id])
      @current_account = session[:current_account_id].present? ? Account.find_by_id(session[:current_account_id]): @current_user.accounts.first
    end
  end

  def clear_current_user
    User.current_user = @current_user= nil
  end

  def wrap_in_transaction
    begin
      ActiveRecord::Base.transaction do
        yield
      end
    end
  end
end
