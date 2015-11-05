class RegistrationsController < Devise::RegistrationsController

  protected

  def after_inactive_sign_up_path_for(resource)
    :new_user_session #respond_to?(:root_path) ? root_path : "/"
  end
end
