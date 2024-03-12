require 'uri'
require 'net/http'
require 'json'

def get_prediction(id)
  api_key = 'c8cfff87ccmsh91391635bfbc4dap1b6917jsnd9e422a92dd4'
  base_url = 'https://api-football-v1.p.rapidapi.com/v3/'
  host = 'api-football-v1.p.rapidapi.com'
  predictions_url = "predictions?fixture=#{id}"

  url = URI(base_url + predictions_url)

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request["X-RapidAPI-Key"] = api_key
  request["X-RapidAPI-Host"] = host

  response = http.request(request)
  JSON.parse(response.read_body)
end

def get_fixtures(league_id, date, season)
  api_key = 'c8cfff87ccmsh91391635bfbc4dap1b6917jsnd9e422a92dd4'
  base_url = 'https://api-football-v1.p.rapidapi.com/v3/'
  host = 'api-football-v1.p.rapidapi.com'
  timezone = "America/Argentina/Cordoba"
  fixtures_url = "fixtures?date=#{date}&league=#{league_id}&season=#{season}&timezone=#{timezone}"

  url = URI(base_url + fixtures_url)

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request["X-RapidAPI-Key"] = api_key
  request["X-RapidAPI-Host"] = host

  response = http.request(request)
  # puts ("response: #{response.read_body}")
  JSON.parse(response.read_body)
end

def extract_advice(data)
  # data['response'][0]['predictions']['advice']
  data['response']
end

def extract_fixtures_ids(fixture_response)
  fixture_response['response'].map do |match|
    fixture_id = match['fixture']['id']
    # home_team_name = match['teams']['home']['name']
    # away_team_name = match['teams']['away']['name']

    # fixture_strings << "#{fixture_id} #{home_team_name} - #{away_team_name}"
    # arr << "#{fixture_id} #{home_team_name} - #{away_team_name}"
  end
end

def get_advices(array)
  advices = []
  predictions_url = 'predictions?fixture='
  array.each do |id|
    advices << extract_advice(get_prediction(id))
  end
  advices
end


# fixtures_ids = []
# days = [24, 25, 26]
# days.each do |day|
#   fixtures_ids << extract_fixtures_ids(get_fixtures(1032, "2024-02-#{day}", 2024))
# end

# 135 serie A, 1032 liga arg, 140 españa, 39 premier

# fixtures_ids = extract_fixtures_ids(get_fixtures(1032, '2024-03-12', 2024))
# advices = get_advices(fixtures_ids)
# puts get_fixtures(1032, '2024-03-12', 2024)
# puts JSON.pretty_generate(get_fixtures(1032, '2024-03-12', 2024))
puts JSON.pretty_generate get_advices([1158598])
