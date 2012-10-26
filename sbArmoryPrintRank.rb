#!/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'json'
require 'net/http'
require "net/https"
require "uri"

region = "eu"
realm = "khaz'goroth"
guild = "Brut des Verderbens"
rank = 0

useragent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.13 (KHTML, like Gecko) Chrome/24.0.1290.1 Safari/537.13"

type = "guild"

if ARGV[0]
  region = ARGV[0]
end

if ARGV[1]
  realm = ARGV[1]
end

if ARGV[2]
  guild = ARGV[2]
end

if ARGV[3]
  rank = Integer(ARGV[3])
end

base_url = "http://#{region}.battle.net/api/wow/#{type}/#{realm}"
url_guild = URI.escape("#{base_url}/#{guild}?fields=members")

#url_char = URI.escape("#{base_url}/?fields=pets")

#resp = Net::HTTP.get_response(URI.parse(url))

num = 1

while num < 10

  uri = URI.parse(url_guild)
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
    print "Error: #{result['reason']} for: #{region}/#{realm}/#{guild}: #{url_guild}\n"
  else
    break
  end

  sleep (10)
  num = num + 1
end


result['members'].each { |d|
  if d['rank'] == rank
    print "#{d['character']['name']}, #{d['character']['class']}, L#{d['character']['level']}=> #{d['character']['thumbnail']}\n"
  end
}

