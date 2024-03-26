require 'uri'
require 'net/http'
require 'json'

API_KEY = ''
BASE_URL = 'https://api-football-v1.p.rapidapi.com/v3/'
HOST_URL = 'api-football-v1.p.rapidapi.com'


def client(url)
  url = URI(BASE_URL + url)

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request["X-RapidAPI-Key"] = API_KEY
  request["X-RapidAPI-Host"] = HOST_URL

  response = http.request(request)
  JSON.parse(response.read_body)
end

def get_prediction(id)
  predictions_url = "predictions?fixture=#{id}"

  client(predictions_url)
end

def get_fixtures(league_id, date, season)
  timezone = "America/Argentina/Cordoba"
  fixtures_url = "fixtures?date=#{date}&league=#{league_id}&season=#{season}&timezone=#{timezone}"
  
  client(fixtures_url)
end

def extract_advice(data)
  # data['response'][0]['predictions']['advice']
  # data['response'][0]['predictions']
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
rescue
  puts fixture_response
end

def get_advices(array)
  advices = []
  array.each do |id|
    advices << get_prediction(id)['response']
  end
  parse_predictions(advices)
end

def parse_minute_data(data)
  goles_por_minuto = []
  porcentajes_por_minuto = []
  data.each do |minute_range, stats|
    goles = stats["total"] || 0
    porcentaje = stats["percentage"] || "0%"
    # Agregar a los arrays
    goles_por_minuto << goles
    porcentajes_por_minuto << porcentaje
  end
  return {
    goals: goles_por_minuto,
    percentages: porcentajes_por_minuto,
  }
 end

def parse_predictions(predictions_response)
  predictions_response.map do |prediction|
    prediction = prediction[0]
    predictions = prediction['predictions']
    teams = prediction['teams']
    comparison = prediction['comparison']

    home = teams['home']
    home_league = home['league']
    home_last5 = home['last_5']
    home_fixtures = home_league['fixtures']
    home_goals_for = home_league['goals']['for']
    home_goals_against = home_league['goals']['against']
    home_minutes_for = parse_minute_data(home_goals_for['minute'])
    home_minutes_against = parse_minute_data(home_goals_against['minute'])

    away = teams['away']
    away_league = away['league'] 
    away_last5 = away['last_5']
    away_fixtures = away_league['fixtures']
    away_goals_for = away_league['goals']['for']
    away_goals_against = away_league['goals']['against']
    away_minutes_for = parse_minute_data(away_goals_for['minute'])
    away_minutes_against = parse_minute_data(away_goals_against['minute'])

    home_minute_goals_for =  home_minutes_for[:goals]
    home_minute_percentages_for = home_minutes_for[:percentages]
    home_minute_goals_against = home_minutes_against[:goals]
    home_minute_percentages_against = home_minutes_against[:percentages]

    away_minute_goals_for = away_minutes_for[:goals]
    away_minute_percentages_for = away_minutes_for[:percentages]
    away_minute_goals_against = away_minutes_against[:goals]
    away_minute_percentages_against = away_minutes_against[:percentages]

    {
      competition: prediction['league']['name'],
      prediction: { 
        advice: predictions['advice'],
        goals_home: predictions['goals']['home'],
        goals_away: predictions['goals']['away'],
        percent_home: predictions['percent']['home'],
        percent_draw: predictions['percent']['draw'],
        percent_away: predictions['percent']['away']
      },
      home: {
        name: home['name'],
        total_games_in_competition: home_league['form'].length,
        last_5: { 
          total: home_last5['played'],
          form: home_last5['form'],
          wins: home_league['form'][-5..-1].nil? ? nil : home_league['form'][-5..-1].count('W'),
          loses: home_league['form'][-5..-1].nil? ? nil : home_league['form'][-5..-1].count('L'),
          draws: home_league['form'][-5..-1].nil? ? nil : home_league['form'][-5..-1].count('D'),
          goals: { 
            for: {
              total: home_last5['goals']['for']['total'],
              average: home_last5['goals']['for']['average'],
            },
            against: {
              total: home_last5['goals']['against']['total'],
              average: home_last5['goals']['against']['average'],
            }
          }
        },
        wins: {
          total: home_fixtures['wins']['total'],
          home: home_fixtures['wins']['home'],
          away: home_fixtures['wins']['away'],
        },
        draws: {
          total: home_fixtures['draws']['total'],
          home: home_fixtures['draws']['home'],
          away: home_fixtures['draws']['away'],
        },
        loses: {
          total: home_fixtures['loses']['total'], 
          home: home_fixtures['loses']['home'], 
          away: home_fixtures['loses']['away'], 
        },
        goals: { 
          for: { 
            total: home_goals_for['total']['total'],
            average_home: home_goals_for['average']['home'],
            average_away: home_goals_for['average']['away'],
            average_total: home_goals_for['average']['total'],
            minutes: home_minute_goals_for,
            minutes_percentage: home_minute_percentages_for,
          },
          against: { 
            total: home_goals_against['total']['total'],
            average_home: home_goals_against['average']['home'],
            average_away: home_goals_against['average']['away'],
            average_total: home_goals_against['average']['total'],
            minutes: home_minute_goals_against,
            minutes_percentage: home_minute_percentages_against,
          }
        }
      },
      away: {
        name: away['name'],
        total_games_in_competition: away_league['form'].length,
        last_5: { 
          total: away_last5['played'],
          form: away_last5['form'],
          wins: away_league['form'][-5..-1].nil? ? nil : away_league['form'][-5..-1].count('W'),
          loses: away_league['form'][-5..-1].nil? ? nil : away_league['form'][-5..-1].count('L'),
          draws: away_league['form'][-5..-1].nil? ? nil : away_league['form'][-5..-1].count('D'),
          goals: { 
            for: {
              total: away_last5['goals']['for']['total'],
              average: away_last5['goals']['for']['average'],
            },
            against: {
              total: away_last5['goals']['against']['total'],
              average: away_last5['goals']['against']['average'],
            }
          }
        },
        wins: {
          total: away_fixtures['wins']['total'],
          home: away_fixtures['wins']['home'],
          away: away_fixtures['wins']['away'],
        },
        draws: {
          total: away_fixtures['draws']['total'],
          home: away_fixtures['draws']['home'],
          away: away_fixtures['draws']['away'],
        },
        loses: {
          total: away_fixtures['loses']['total'], 
          home: away_fixtures['loses']['home'], 
          away: away_fixtures['loses']['away'], 
        },
        clean_sheets: {
          total: away_league['clean_sheet']['total'],
          home: away_league['clean_sheet']['home'],
          away: away_league['clean_sheet']['away'],
        },
        goals: { 
          for: { 
            total: away_goals_for['total']['total'],
            average_home: away_goals_for['average']['home'],
            average_away: away_goals_for['average']['away'],
            average_total: away_goals_for['average']['total'],
            minutes: away_minute_goals_for,
            minutes_percentage: away_minute_percentages_for,
          },
          against: { 
            total: away_goals_against['total']['total'],
            average_home: away_goals_against['average']['home'],
            average_away: away_goals_against['average']['away'],
            average_total: away_goals_against['average']['total'],
            minutes: away_minute_goals_against,
            minutes_percentage: away_minute_percentages_against,

          },
        },
      },
    }
  end
end
# fixtures_ids = []
# days = [24, 25, 26]
# days.each do |day|
#   fixtures_ids << extract_fixtures_ids(get_fixtures(1032, "2024-02-#{day}", 2024))
# end

# 135 serie A, 1032 liga arg, 140 españa, 39 premier, 3 Europa League, 848 conference league 
# 2 Champions league, 78 bundes, 45 fa cup, 129 primera nacional, 525 champions women, 190 a league wom
# 906 reserva copa de la liga, 130 copa arg
fixtures_ids = extract_fixtures_ids(get_fixtures(190,'2024-03-24', 2024))
# fixtures_ids2 = extract_fixtures_ids(get_fixtures(135, '2024-03-17', 2023))
# fixtures_ids = extract_fixtures_ids(get_fixtures(39, '2024-03-16', 2024))
# fixtures_ids = extract_fixtures_ids(get_fixtures(39, '2024-03-16', 2024))
advices = get_advices(fixtures_ids)
# advices2 = get_advices(fixtures_ids2)
puts JSON.pretty_generate advices
puts advices.count
puts '=' * 50
# puts JSON.pretty_generate advices2
# puts advices2.count

# puts get_fixtures(1032, '2024-03-12', 2024)
# puts JSON.pretty_generate(get_fixtures(1032, '2024-03-12', 2024))
# puts JSON.pretty_generate get_advices([1158598])
