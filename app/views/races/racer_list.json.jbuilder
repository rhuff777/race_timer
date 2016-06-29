json.array!(@racers) do |racer|
  json.text "#{racer.bib} #{racer.name} #{racer.boat_class}"
  json.value racer.id.to_str
end
