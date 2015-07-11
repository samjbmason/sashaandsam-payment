require 'rubygems'
require 'bundler'
Bundler.require

Dotenv.load

Redis::Objects.redis = Redis.new(url: ENV['REDIS_URL'])

require './app'
run App