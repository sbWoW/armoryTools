#!/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'json'
require 'net/http'
require 'net/https'
require 'uri'
require 'sqlite3'

def insertFaction(id, faction)
  query = "select count(*) from faction where id = ?"
  retVal = $db.execute(query, id)
  if retVal[0][0] == "0"
    query = "insert into faction (id, name) values (?, ?);"
    $db.execute(query, id, faction)
  end
end

def insertCharacter(region, realm, name, guild, comment, url)
  p "new character: #{region}/#{realm}/#{name}"
  query = "insert into character (id, region, realm, name, guild, comment, url, autoscan) values ((select max(id)+1 from character), ?, ?, ?, ?, ?, ?, 1);"
  $db.execute(query, region, realm, name, guild, comment, url)
end

def getCharacter(region, realm, name)
  query = "select id,region,realm,name,guild,comment,url from character where region=? and realm=? and name=?;"
  result = $db.execute(query, region, realm, name)
  if result.nil?
    return nil
  else
    return result[0]
  end
end

def getAutoscanCharacters()
  query = "select id,region,realm,name,guild,comment,url from character where autoscan=1;"
  result = $db.execute(query)
  return result
end

def getRepValueToday(characterid, factionid) 
  query = "select value from reputation where characterid=? and factionid=? and date(date)=date('now')"
  result = $db.execute(query, characterid, factionid)
  if result.nil?
    return nil
  else
    return result[0]
  end
end

def setRepValue(characterid, factionid, value, standing, max)
  if getRepValueToday(characterid, factionid).nil?  
    query = "insert into reputation (characterid, factionid, value, standing, max, date) values (?, ?, ?, ?, ?, datetime('now'));"
    $db.execute(query, characterid, factionid, value, standing, max)    
      print "+"
  else
    if $upd == 1
      query = "update reputation set value=?, standing=?, max=?,date=datetime('now') where characterid=? and factionid=? and date(date)=date('now');"
      $db.execute(query, value, standing, max, characterid, factionid)  
      print "*"
    else
      print "-"
    end    
  end
end

def getArmoryData(region, realm, name)

  base_url = "http://#{region}.battle.net/api/wow/character/#{realm}/#{name}"

  useragent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.13 (KHTML, like Gecko) Chrome/24.0.1290.1 Safari/537.13"

  num = 0

  while num < 10
    url = URI.escape("#{base_url}?fields=reputation,guild")

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
      print "Error: #{result['reason']} for: #{region}/#{realm}/#{name}\n"    
    else
      break
    end

    print "s"
    sleep (10)
    num = num + 1
  end

  return result
end

def processData(data, region)
  character = getCharacter(region, data['realm'], data['name'])

  if character.nil?
    guild = ''
    if !data['guild'].nil?
      guild = data['guild']['name']
    end
    insertCharacter(region, data['realm'], data['name'], guild, '', '')
    character = getCharacter(region, data['realm'], data['name'])
  end

  data['reputation'].each { |d|
    insertFaction(d['id'], d['name'])
    setRepValue(character[0], d['id'], d['value'], d['standing'], d['max'])
    #print "#{d['name']} => #{d['standing']} / #{d['value']}\n"
  }
end

$db = SQLite3::Database.new( 'wowRep.db' )

data = nil

if ARGV[0] == "allupd"
  $upd = 1
end

if ARGV[0] and ARGV[1] and ARGV[2]
  data = getArmoryData(ARGV[0], ARGV[1], ARGV[2])
  processData(data, ARGV[0])
  print " - done\n"
else 
  if ARGV[0] == "all" or ARGV[0] == "allupd"
  getAutoscanCharacters().each { |c|
    print "update: #{c[1]}/#{c[2]}/#{c[3]} "
    data = getArmoryData(c[1], c[2], c[3])
    processData(data, c[1])
    print " - done\n"
  }
  end
end

