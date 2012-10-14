#!/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'json'
require 'net/http'
require "net/https"
require "uri"

region = "eu"
realm = "khaz'goroth"
character = "Smb"

useragent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.13 (KHTML, like Gecko) Chrome/24.0.1290.1 Safari/537.13"

if ARGV[0]
  character = ARGV[0]
end

if ARGV[1]
  realm = ARGV[1]
end

if ARGV[2]
  region = ARGV[2]
end

base_url = "http://#{region}.battle.net/api/wow/character/#{realm}/#{character}"
url = URI.escape("#{base_url}?fields=pets")

#resp = Net::HTTP.get_response(URI.parse(url))

num = 1

while num < 10

  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request.initialize_http_header({"User-Agent" => useragent})
  resp = http.request(request)
  data = resp.body

  result = JSON.parse(data)

  if result.has_key? 'Error'
    raise "web service error"
  end

  if result['status'] == "nok"
    print "Error: #{result['reason']} for: #{region}/#{realm}/#{character}\n"
  else
    break
  end

  sleep (10)
  num = num + 1
end

result['pets']['collected'].each { |d|
  if d['name'] != d['creatureName']
    print "#{d['name']} (L: #{d['stats']['level']}) => #{d['creatureName']}\n"
  end
}

