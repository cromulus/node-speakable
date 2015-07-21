require 'rubygems'
require 'fast-stemmer'
require 'stopwords'
require 'sinatra'
require "sinatra/streaming"
require 'json'
require 'redis'
require 'eventmachine'
require 'em-hiredis'


# all_words ==> SET of words
# new_words_today_count:Date.today => number
# new_words_today:Date.today => set of words
# total_words_today:Date.today => number
# total_word_count => number
configure do
  set :redis, Redis.new
  set :hiredis, EM::Hiredis.connect
end


post "/words" do #127.0.0.1/words
  @redis = settings.redis
   #params= request.env['rack.request.query_hash']
  #File.open("/tmp/wordlog", "a") { |file|  file.write(params)}
  @json = JSON.parse(request.body.read)


  words=@json['words']

  # filter = Stopwords::Snowball::Filter.new "en"

  # words = filter.filter params[:words]

  words.each do |w|
    w.downcase!

    next if Stopwords.is?(w)

    word = Stemmer::stem_word(w)

    if !@redis.sismember('all_words',word)
      @redis.incr("new_words:#{Date.today}")
      @redis.sadd("all_words",word)
      @redis.sadd("new_words_today:#{Date.today}",word)
    end

    @redis.incr("total_word_count")
    @redis.incr("total_word_count:#{Date.today}")

    @redis.zincrby("topwords",1,word)
    @redis.publish('updated',Time.now)
  end
  puts words.length
end

get "/data" do
  @redis = settings.redis

  result={}
  result[:total_word_count] = @redis.get('total_word_count')
  result[:todays_word_count]= @redis.get("total_word_count:#{Date.today}")
  result[:new_words_today] = @redis.smembers("new_words_today:#{Date.today}")
  result[:new_words_today_count] = @redis.scard("new_words_today:#{Date.today}")
  result[:all_words] = @redis.scard('all_words')
  result[:top_ten_words] = @redis.zrange('topwords',0,10)

  return result.to_json
end

get '/stream' do

  subscriber.psubscribe 'updated'
  stream :keep_open  do |out|
    out << "started streaming"
    subscriber.on(:pmessage) do |key, channel, message|
      subscriber.punsubscribe 'updated' if out.closed?
      out << "#{message}" unless out.closed?
    end
  end
end
