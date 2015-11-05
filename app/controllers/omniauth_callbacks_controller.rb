class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def instagram
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @account = Account.find_for_oauth_provider(request.env["omniauth.auth"])

    if @account.persisted?
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.instagram_data"] = @user
      redirect_to new_user_registration_url
    end
  end


end
