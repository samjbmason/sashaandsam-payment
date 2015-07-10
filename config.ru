require 'rubygems'
require 'bundler'
Bundler.require

Dotenv.load

$redis = Redis.new(url: ENV['REDIS_URL'])

require './app'
run App