class Race
  include Mongoid::Document

  field :name, type: String
  field :current_heat, type: String, default: "Heat 1"
	field :round_start_interval, type: Integer, default: 60
	field :start_date, type: Date
	field :lock_racer_list_finish, type: Boolean, default: true
	field :auto_sync, type: Boolean, default: false
	field :auto_start, type: Boolean, default: false

	has_many :racers
	has_many :runs

  def next_racer_order
		if self.racers.blank?
			return 1
		else
    	r = self.racers.order('order ASC').last
			r.order + 1
		end
  end

end
