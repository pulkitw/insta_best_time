class Account < ActiveRecord::Base

  def self.first_or_create_with_user account, access_token
    a  = self.where(u_id: account[:id]).first_or_initialize
    if a.id.nil?
      a.user_id = User.current_user.present? ? User.current_user.id : User.create!(username: account[:username]).id
      a.username = account[:username]
      a.name = account[:name]
      a.secret_token = access_token
      a.save!
    end
    a
  end

  def set_best_time best_time
    update_attributes(best_time: best_time, last_calculated_time: Time.now)
  end

=begin
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :omniauth_providers => [:instagram]
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  def self.find_for_oauth_provider(access_token)
    #assuming only one provider instagram
    account = Account.where(:u_id => access_token["uid"]).first
    unless account
      data = access_token.info
      account = Account.where(:email=>data["email"]).first
      unless account
        account = Account.new(name: data["name"],
                                  email: data["email"],
                                  password: Devise.friendly_token[0,20],
                                  uid: access_token['uid'],
                                  provider: access_token['provider']
        )
      end
    end
    account
  end
=end

end
