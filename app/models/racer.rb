class Racer
  include Mongoid::Document
  field :name, type: String
  field :bib, type: String
  field :order, type: Integer
  field :boat_class, type: String
  field :age_class, type: String, default: "open"
  field :start, type: DateTime
	field :heats, type: Array, default: []

	belongs_to :race
	has_many :runs, dependent: :destroy

#	validates :bib, presence: true
	validates :boat_class, presence: true
	validate :name_or_bib
	validate :bib_and_boat_class

	before_save :convert_to_lower_case
	before_save :setup_bib
	before_save :inject_into_runs

	def inject_into_runs
		if self.changed.include?('age_class') or self.changed.include?('bib')
			self.runs.each do |run|
				run.age_class = self.age_class
				run.boat_class = self.age_class
				run.bib = self.bib
				run.save
			end
		end
	end


	def entry
		"#{boat_class} | #{bib} | #{name}"
	end


	private
		def bib_and_boat_class
			#bib must have the boat class abbr on the end
			true
		end

		def convert_to_lower_case
			self.boat_class = self.boat_class.downcase
			if !self.age_class.blank?
				self.age_class = self.age_class.downcase
			end
		end

    def name_or_bib
      if name.blank? and bib.blank?
        errors.add(:base, "Specify a name or a bib")
      end
    end

		def setup_bib
			if self.bib.blank?
				unless self.name.blank?
					names = self.name.split(' ')
					if names.length == 1
						bib = names[0][0...2] || names[0]
						bib += bc_abbrev(self.boat_class)
						self.bib = bib.downcase
					else
						in1 = names[0][0...1] || names[0]
						in2 = names[1][0...1] || names[1]
						bib = in1+in2+bc_abbrev(self.boat_class)
						self.bib = bib.downcase
					end
				end
			end
			unless self.bib.blank?
				if self.boat_class.blank? or self.boat_class == "zz"
					if self.bib.length > 2
						bc = aboat_class(self.bib.last(2))
						unless bc.blank?
							self.boat_class = bc 
						end	
					end
				end
			end
		end

		def aboat_class(bc)
			case bc.downcase
				when "km"
					return "k1m"
				when "cm"
					return "c1m"
				when "kw"
					return "k1w"
				when "cw"
					return "c1w"
				when "cc"
					return "c2"
				when "c2"
					return "c2"
				when "oc"
					return "oc1"
				when "oo"
					return "oc2"
				when "o1"
					return "oc1"
				when "o2"
					return "oc2"
				else
					return nil
			end
		end

		def bc_abbrev(boat_class)
			case boat_class.downcase
				when "k1m"
					return "km"
				when "c1m"
					return "cm"
				when "k1w"
					return "kw"
				when "c1w"
					return "kw"
				when "c2"
					return "cc"
				when "oc1"
					return "oc"
				when "oc2"
					return "oo"
				else
					return "zz"
			end
		end

		def bc_abbrev(boat_class)
			case boat_class.downcase
				when "k1m"
					return "km"
				when "c1m"
					return "cm"
				when "k1w"
					return "kw"
				when "c1w"
					return "kw"
				when "c2"
					return "cc"
				when "oc1"
					return "oc"
				when "oc2"
					return "oo"
				else
					return "zz"
			end
		end
end
