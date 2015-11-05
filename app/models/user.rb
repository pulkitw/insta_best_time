class User < ActiveRecord::Base
  has_many :accounts

  class << self
    attr_accessor :current_user
  end
end
