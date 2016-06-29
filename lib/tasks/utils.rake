namespace :utils do

  desc "Best of"
  task(:best_of => :environment) do
		@race = Race.find_by(:name => "Race 1")
		puts "#{@race.name}"
		@heat1 = "Heat 1"
		@heat2 = "Heat 2"
		@best_of_heats = []
		@race.racers.each do |racer|
			h = racer.as_json
			run1 = racer.runs.find_by(:heat => @heat1).as_json
			puts run1
			run2 = racer.runs.find_by(:heat => @heat2).as_json
			puts run2
			h['run1'] = run1
			h['run2'] = run2
			if !run1.blank? and !run2.blank?
				if !run1['score'].blank? and !run2['score'].blank?
					h['best'] = run1['score'] < run2['score'] ? run1['score'] : run2['score']
				else
					if !run1['score'].blank?
						h['best'] = run1['score']
					else
						h['best'] = run2['score']
					end
				end
			else
				if !run1.blank?
					if !run1['score'].blank?
						h['best'] = run1['score']
					else
						h['best'] = ''
					end
				else
					if !run2['score'].blank?
						h['best'] = run2['score']
					else
						h['best'] = ''
					end
				end
			end
			@best_of_heats.push h
		end
		foo = @best_of_heats.sort { |a,b| [a[:boat_class], a[:best]] <=> [b[:boat_class], b[:best]] }
		foo.each do |f|
			puts f
			puts
		end 
  end

end
