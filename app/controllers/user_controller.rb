class UserController < ApplicationController

  require 'open-uri'
  require 'uri'
  require 'net/http'
  require 'net/https'
  require 'json'
  CALLBACK_URL = "http://localhost:3000/user/callback"
  THRESHOLD_HOURS = 6
  THRESHOLD_FOLLOWERS = 50

  def sign_in
    redirect_to Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
  end

  def sign_out
    session[:current_user_id] = nil
    redirect_to user_index_path
  end

  def callback
    response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
    if response.present? && response.user.present?
      account = Account.first_or_create_with_user response.user, response.access_token
      session[:current_user_id] = account.user_id
    end
    redirect_to user_index_path
  end

  def add_account
    redirect_to Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
  end

  def select_account
    session[:current_account_id] = params[:account_id]
    @current_account = session[:current_account_id].present? ? Account.find_by_id(session[:current_account_id]): @current_user.accounts.first
    render user_index_path
  end

  def get_best_time
    a = @current_account
    if a.best_time.present? && a.last_calculated_time >= Time.now - THRESHOLD_HOURS.hours
      @best_time = a.best_time
    else
      c_time = get_followers_last_post
      @best_time = "day: #{get_max_day(c_time)}, time: #{get_max_time(c_time)}"
      @current_account.set_best_time @best_time
    end
    render user_index_path
  end


  def limits
    client = Instagram.client(:access_token => @current_account.secret_token)
    puts response = client.utils_raw_response.headers
    render plain: response
  end

  def fetch(url, response = '')
    Rails.cache.fetch(url) do
      result = nil
      begin
        open(url) { |f| f.each_line { |line| response += line } }
        result = JSON.parse(response)
      rescue OpenURI::HTTPError
        nil
      end
      result
    end
  end

  def get_followers
    raise "Invalid Params." unless @current_account
    next_url = "https://api.instagram.com/v1/users/self/followed-by?access_token=#{@current_account.secret_token}"
    followers = {}

    while next_url && followers.keys.count < THRESHOLD_FOLLOWERS
      result = fetch(next_url)
      if result.present?
        next_url = result['pagination']['next_url']
        result['data'].each { |data| followers.merge!(data['username'] => data['id']) }
      else
        next_url = nil
      end
      p followers.count
    end
    return followers
  end

  def get_followers_last_post
    followers = get_followers #.select.with_index { |h, i| i<200 }
    last_post = {}
    created_time = []
    count = 0
    followers.each do |u, id|
      response = fetch("https://api.instagram.com/v1/users/#{id}/media/recent/?count=1&access_token=#{@current_account.secret_token}")
      data = response['data'].first if response.present? && response['data'].present?
      puts count +=1
      next unless data.present?
      created_time << c_time = Time.at(data['created_time'].to_i)
      last_post[u.to_s] = {id: id, link: data['link'], created_time: c_time}
    end
    last_post
    created_time
  end

  private
  def get_max_day c_time
    days = c_time.inject(Hash.new(0)) { |h, t| h[t.strftime('%A')] +=1; h }
    days = Hash[days.sort { |a, b| b[1] <=> a[1] }]
    days.max_by { |k, v| v }[0]
  end

  def get_max_time c_time
    times = c_time.inject(Hash.new(0)) { |h, t| h[t.strftime('%H')] +=1; h }
    times = Hash[times.sort { |a, b| b[1] <=> a[1] }]
    "#{times.max_by { |k, v| v }[0]} Hours"
  end
end
