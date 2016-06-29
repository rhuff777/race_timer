json.array!(@runs) do |run|
  json.extract! run, :id, :start, :finish, :heat, :raw_time, :total_penalties, :score
  json.url run_url(run, format: :json)
end
