module RacersHelper

	def highlightOnCourse(run)
		if run['run2'].blank? 
			if run['run1'].blank? 
				return "no-highlight"
			else 
				if run['run1']['status'] == 'Started' 
					return 'on-course'
				else
					return "no-highlight"
				end 
			end 
		else 
			if run['run2']['status'] == 'Started'  
				return 'on-course'
			else 
				return "no-highlight"
			end 
		end 
	end

	def highlightLastRun(run, last_run)
		if last_run.blank?
				return "no-highlight"
		else 
			if run['run2'].blank? 
				if run['run1'].blank? 
					return "no-highlight"
				else 
					if run['run1']['_id'] == last_run.id  
						return 'last-run'
					else
						return "no-highlight"
					end 
				end 
			else 
				if run['run2']['_id'] == last_run.id  
					return 'last-run'
				else 
					return "no-highlight"
				end 
			end 
		end 
	end
end
