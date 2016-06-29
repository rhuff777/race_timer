json.array!(@racers) do |racer|
  json.extract! racer, :id, :name, :bib, :order, :boat_class, :age_class
  json.url racer_url(racer, format: :json)
end
