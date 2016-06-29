json.array!(@races) do |race|
  json.extract! race, :id, :name, :current_heat
  json.url race_url(race, format: :json)
end
