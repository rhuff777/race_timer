class Run
  include Mongoid::Document
  field :start, type: DateTime
  field :finish, type: DateTime
  field :heat, type: String
  field :raw_time, type: Float
  field :total_penalties, type: Integer, default: 0
  field :score, type: Float
	field :bib
	field :boat_class
	field :status, type: String, default: "New"
	field :age_class, type: String, default: "open"
	belongs_to :race
	belongs_to :racer


	validates :bib, presence: true
	validates :boat_class, presence: true

	before_save :convert_to_lower_case
	before_save :compute_score
	before_save :inject_racer
	before_save :check_status
	after_save :update_racer
	before_destroy :clean_racer

	def check_status
		if self.changed.include?('finish')
			if self.finish.blank?
				if self.status == 'Finished'
					self.status = 'Started'
				end
			else
				self.status = 'Finished'
			end
		end
	end
		
	def clean_racer
		if !self.racer.blank?
			self.racer.heats.delete(self.heat)
			self.racer.save
		end
	end

	def update_racer
		if !self.racer.blank?
			if !self.racer.heats.include?(self.heat)
				self.racer.heats.push(self.heat)
				self.racer.save
			end
		end
	end

	def inject_racer
		if !self.racer.blank?
			self.age_class = self.racer.age_class
			self.bib = self.racer.bib
			self.boat_class = self.racer.boat_class
		end
	end

	def compute_score
		if !self.start.blank? and !self.finish.blank? and self.status.downcase != 'dns' and self.status.downcase != 'dnf' and self.status.downcase != 'dq'
			self.raw_time = ((self.finish - self.start) * 86400.0).round(2)
      self.score = self.raw_time + self.total_penalties	
		else
			self.score = nil
		end
	end

  def start_string
		if self.start.blank?
			self.start.to_s
		else
    	self.start.strftime('%Y-%m-%dT%2H:%2M:%2S.%2L UTC')
		end
  end

  def start_string=(start_str)
		if start_str.blank?
			self.start = nil
		else
    	self.start = Time.parse(start_str)
		end
	end


  def finish_string
		if self.finish.blank?
			self.finish.to_s
		else
    	self.finish.strftime('%Y-%m-%dT%2H:%2M:%2S.%2L UTC')
		end
  end

  def finish_string=(finish_str)
		if finish_str.blank?
			self.finish = nil
		else
    	self.finish = Time.parse(finish_str)
		end
	end

	private
		def convert_to_lower_case
			self.boat_class = self.boat_class.downcase
		end
end
