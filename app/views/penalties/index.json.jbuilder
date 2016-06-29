json.array!(@penalties) do |penalty|
  json.extract! penalty, :id, :gates
  json.url penalty_url(penalty, format: :json)
end
