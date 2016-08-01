class RacesController < ApplicationController
  before_action :set_race, only: [:show, :edit, :update, :destroy, :start_run, :start_run_form, :auto_start_run, :auto_start_run_form, :test_auto_start, :finish_run, :finish_run_form, :next_heat, :clear_runs, :clear_racers, :inline_update, :starts, :finishes, :sync_finish, :sync_finishes, :results, :dashboard, :print_start_order, :racer_list, :check_for_more_runs, :score_strips, :clear_unstarted_finishes, :authorize_finish]
	protect_from_forgery except: [:finish_run, :start_run, :save_all_racers, :auto_start_run, :test_auto_start]

	def print_start_order

	end

	def racer_dashboard
	end

	def racer_list
		#unless params[:racer].blank?
		if true
    	@racers = @race.racers.all.order_by(:order => "asc")
		else
			#racers that don't have a run in this heat
			bibs = @race.runs.where(:finish.ne => nil).distinct("bib")
			@racers = @race.racers.not_in(:bib => bibs).order_by(:order => "asc")
			if @racers.blank?
    		@racers = @race.racers.all.order_by(:order => "asc")
			end
		end
	end

	def save_all_racers
		racers = params["_json"]
		racers.each_with_index do |r, i|
			racer = Racer.find_by(:_id => r["id"]["$oid"])
			racer.order = i+1
			racer.save
		end
    respond_to do |format|
  		format.json { head :no_content }
		end
	end

  # GET /races
  # GET /races.json
  def index
    @races = Race.all.order_by(:start_date => 'desc')
  end

  # GET /races/1
  # GET /races/1.json
  def show
  end

  # GET /races/new
  def new
    @race = Race.new
		@race.start_date = Date.today
  end

	def results
		unless params[:heat]
	    @runs_by_heat = @race.runs.all.order_by(:heat => 'desc', :boat_class => 'asc', :score => 'asc')
	    @runs_by_heat_by_age = @race.runs.all.order_by(:heat => 'desc', :boat_class => 'asc', :age_class => 'asc', :score => 'asc')
		else
	    @runs_by_heat = @race.runs.where(:heat => params[:heat]).order_by(:heat => 'desc', :boat_class => 'asc', :score => 'asc')
	    @runs_by_heat_by_age = @race.runs.where(:heat => params[:heat]).order_by(:heat => 'desc', :boat_class => 'asc', :age_class => 'asc', :score => 'asc')
		end
		@unfinished_runs = @race.runs.where(:finish => nil, :start.ne => nil, :heat => @race.current_heat, :status => "Started").order_by(:start => 'asc')
		@unstarted_racers = @race.racers.where(:heats.ne => "Heat 1").order_by(:order => 'asc')	
		@last_run = @race.runs.order(:finish => :desc).first
		@best_of_heats = getBestOfHeats
		@best_of = @best_of_heats.sort_by { |x| [x["boat_class"], x["best"]] }
		@best_of_by_age = @best_of_heats.sort_by { |x| [x["boat_class"], x["age_class"], x["best"]] }
	end

	def dashboard
		@unfinished_runs = @race.runs.where(:finish => nil, :start.ne => nil, :heat => @race.current_heat, :status => "Started").order_by(:start => 'asc')
		@unstarted_racers = @race.racers.where(:heats.ne => @race.current_heat).order_by(:order => 'asc')	
		@last_run = @race.runs.order(:finish => :desc).first
		@best_of_heats = getBestOfHeats
		@best_of = @best_of_heats.sort_by { |x| [x["boat_class"], x["best"]] }
		@best_of_by_age = @best_of_heats.sort_by { |x| [x["boat_class"], x["age_class"], x["best"]] }
	end


	def getBestOfHeats
		@heat1 = "Heat 1"
		@heat2 = "Heat 2"
		best_of_heats = []
		@race.racers.each do |racer|
			h = racer.as_json
			run1 = racer.runs.find_by(:heat => @heat1).as_json
			run2 = racer.runs.find_by(:heat => @heat2).as_json
			if run1.blank?
				if run2.blank?
					next
				else
					if run2['start'].blank? or run2['finish'].blank?
						next
					end
				end
			end
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
						h['best'] = 9999
					end
				else
					if !run2.blank? and !run2['score'].blank?
						h['best'] = run2['score']
					else
						h['best'] = 9999
					end
				end
			end
			best_of_heats.push h
		end
		return best_of_heats
	end

	def starts
    @runs = @race.runs.all.order_by(:start => 'asc')
	end

	def finishes
    @runs = @race.runs.where(:finish.ne => nil, :heat => @race.current_heat).order_by(:finish => 'asc')
		#@unfinished_runs = @race.runs.where(:finish => nil, :start.ne => nil, :heat => @race.current_heat).order_by(:start => 'asc')
		@unfinished_runs = @race.runs.where(:finish => nil, :start.ne => nil, :heat => @race.current_heat, :status => "Started").order_by(:start => 'asc')
	end

	def clear_unstarted_finishes
	  runs = @race.runs.where(:finish.ne => nil, :start => nil,  :heat => @race.current_heat, :boat_class => "zz")
		runs.destroy_all
		redirect_to finishes_race_url(@race), notice: "Unstarted finishes cleared successfully."
	end
	def sync_finish
		# this syncs last finished run with last unfinished run
		@last_completed_run = @race.runs.where(:finish.ne => nil, :start.ne => nil, :heat => @race.current_heat, :status => "Finished").order_by(:finish => 'asc').last
		unless @last_completed_run.blank?
	    run = @race.runs.where(:finish.ne => nil, :start => nil,  :heat => @race.current_heat, :boat_class => "zz", :finish.gt => @last_completed_run.finish).order_by(:finish => 'asc').last
		else
	    run = @race.runs.where(:finish.ne => nil, :start => nil,  :heat => @race.current_heat, :boat_class => "zz").order_by(:finish => 'asc').last
		end
		auto_sync_finish(run)
		redirect_to finishes_race_url(@race), notice: "Start / Finish sync complete"
	end

	def sync_finishes
		# this syncs last finished run with last unfinished run
		do_sync_finishes
		redirect_to finishes_race_url(@race), notice: "Start / Finish sync complete for all unfinished starts"
	end


	def do_sync_finishes
		matches = 0
    @runs = @race.runs.where(:finish.ne => nil, :heat => @race.current_heat, :bib => "zz").order_by(:finish => 'asc')
		@last_completed_run = @race.runs.where(:finish.ne => nil, :start.ne => nil, :heat => @race.current_heat, :status => "Finished").order_by(:finish => 'asc').last
		@unfinished_runs = @race.runs.where(:finish => nil, :start.ne => nil, :heat => @race.current_heat, :status => "Started").order_by(:start => 'asc')
		@unfinished_runs.each do |urun|
			#find and finished run with zz racer that matches this start 		
			unless @last_completed_run.blank?
    		run = @race.runs.where(:finish.ne => nil, :start => nil, :heat => @race.current_heat, :boat_class => "zz", :finish.gt => @last_completed_run.finish).order_by(:finish => 'asc').first
			else
    		run = @race.runs.where(:finish.ne => nil, :start => nil, :heat => @race.current_heat, :boat_class => "zz").order_by(:finish => 'asc').first
			end
			unless run.blank?
				if run.id != urun.id
					run.start = urun.start
					racer = urun.racer
					urun.destroy
					run.bib = racer.bib
					run.boat_class = racer.boat_class
					racer.runs << run
				end
			end
		end
	end

	def auto_sync_finish(run)
		unless run.blank?
			matches = 0
  	  @runs = @race.runs.where(:finish.ne => nil, :heat => @race.current_heat, :bib => "zz").order_by(:finish => 'asc')
			@urun = @race.runs.where(:finish => nil, :start.ne => nil, :start.lt => run.finish, :heat => @race.current_heat, :status => "Started").order_by(:start => 'asc').first
			#find a finished run with zz racer that matches this start 		
			if  !run.blank? and !@urun.blank?
				if run.id != @urun.id
					run.start = @urun.start
					racer = @urun.racer
					@urun.destroy
					run.bib = racer.bib
					run.boat_class = racer.boat_class
					racer.runs << run
				end
			end
		end
	end

	def authorize_finish
		@urun = Run.find(params[:run_id])
	  run = @race.runs.where(:finish.ne => nil, :start => nil,  :heat => @race.current_heat, :boat_class => "zz", :finish.gt => @urun.start).order_by(:finish => 'asc').first
  	@runs = @race.runs.where(:finish.ne => nil, :heat => @race.current_heat, :bib => "zz").order_by(:finish => 'asc')
		#find a finished run with zz racer that matches this start 		
		if  !run.blank? and !@urun.blank?
			if run.id != @urun.id
				run.start = @urun.start
				racer = @urun.racer
				@urun.destroy
				run.bib = racer.bib
				run.boat_class = racer.boat_class
				racer.runs << run
			end
		end
		redirect_to finishes_race_url(@race), notice: "Start / Finish sync complete"
	end

	def score_strips
    @racers = @race.racers.all.order_by(:order => "asc")
	end

	def clear_racers
		@race.racers.destroy_all
		@race.current_heat = 'Heat 1'
		@race.save
    respond_to do |format|
      format.html { redirect_to races_url, notice: 'All racers were successfully destroyed.' }
      format.json { head :no_content }
    end
	end

	def clear_runs
		@race.runs.destroy_all
		@race.current_heat = 'Heat 1'
		@race.save
    respond_to do |format|
      format.html { redirect_to races_url, notice: 'All runs were successfully destroyed.' }
      format.json { head :no_content }
    end
	end

	def next_heat
		heat = @race.current_heat
		base = heat.split(' ')[0]
		cnt = heat.split(' ')[1].to_i
		@race.current_heat = "#{base} #{cnt+1}"
    respond_to do |format|
      if @race.save
        format.html { redirect_to races_path, notice: 'Heat was successfully updated.' }
        format.json { render :show, status: :ok, location: @race }
      else
        format.html { redirect_to races_path, notice: 'Unable to increment heat.' }
        format.json { render json: @race.errors, status: :unprocessable_entity }
      end
    end

	end

	def test_auto_start
		#get the last run started
		starts = @race.runs.where(heat: @race.current_heat, status: "Started").order_by(:start => "desc")
		@run = starts.first
		#set the prestart time to the posted time
		unless @run.blank?
			@run.prestart = Time.parse(params[:run][:start])
			message = 'prestart for last start was successfully set.'
		end
    respond_to do |format|
			unless @run.blank?
	      if @run.save
		      format.html { redirect_to auto_start_run_form_race_path(@race), notice: message }
  		    #format.json { render :show, status: :created, location: @race }
					format.js {}
      		format.json { render status: :created }
	      else
  	      format.html { redirect_to auto_start_run_form_race_path(@race), notice: 'Prestart could not be set: save failed'}
    	    format.json { render json: @race.errors, status: :unprocessable_entity }
      	end
			else
  	      format.html { redirect_to auto_start_run_form_race_path(@race), notice: 'Prestart could not be set: no runs'}
    	    format.json { render json: @race.errors, status: :unprocessable_entity }
			end
    end
	end

	def auto_start_run_form
		@run = Run.new
		@run.start = Time.now.strftime("%T")
	end

	def auto_start_run
		#find the most recent PreStarted run
		prestarts = @race.runs.where(heat: @race.current_heat, status: "PreStarted").order_by(:prestart => "desc")
		@run = prestarts.first
		#set the start time
		unless @run.blank?
			unless params[:run][:start].blank?
				@run.start = Time.parse(params[:run][:start])
				@run.status = "Started"
			end
			message = 'PreStarted run was successfully started.'
		else
			@run = Run.new
			if !params['bib_box'].blank?
				@bib = params['bib_box']
			else
				@bib = params[:run][:bib]
			end
			if @bib.blank?
				@bib="#{Time.now}_zz"
			end
			@run.bib = @bib
			@run.boat_class = get_boat_class(@bib)
			if params[:run][:start].blank?
				@run.start = Time.now.round_off(@race.round_start_interval)
			else
				@run.start = Time.parse(params[:run][:start])
			end
			if !@race.runs.where(bib: @bib, boat_class: @boat_class, heat: @race.current_heat ).blank?
				@run.heat = "#{@race.current_heat}_#{Time.now}"
			else
				@run.heat = @race.current_heat
			end
			if !@run.bib.blank?
				if @race.racers.where(bib: @run.bib).blank?
					@racer = Racer.new(:bib => @run.bib, :name => @run.bib, :boat_class => get_boat_class(@run.bib))
					@racer.order = @race.next_racer_order
					@race.racers << @racer
					@racer.save
				else
					@racer = @race.racers.find_by(bib: @run.bib)
				end
			end
			if !@race.blank?
				@race.runs << @run
			end
			if !@racer.blank?
				@racer.runs << @run
			end
			message = 'NOT Prestarted! Run was successfully started anyway.'
		end
		@run.status = "Started"
    respond_to do |format|
			unless @run.blank?
	      if @run.save
					if @run.start.blank?
	  	      format.html { redirect_to auto_start_run_form_race_path(@race), notice: 'Run could not be started: no start time'}
  	  	    format.json { render json: @race.errors, status: :unprocessable_entity }
					else
		        format.html { redirect_to auto_start_run_form_race_path(@race), notice: message }
  		      #format.json { render :show, status: :created, location: @race }
						format.js {}
      		  format.json { render status: :created }
					end
	      else
  	      format.html { redirect_to auto_start_run_form_race_path(@race), notice: 'Run could not be started.'}
    	    format.json { render json: @race.errors, status: :unprocessable_entity }
      	end
			else
  	      format.html { redirect_to auto_start_run_form_race_path(@race), notice: 'Run could not be started: no prestarts'}
    	    format.json { render json: @race.errors, status: :unprocessable_entity }
			end
    end
	end  

# GET /races/1/start_run_form
  def start_run_form
		@racers = @race.racers.order_by(:order => 'asc')
		#@runs = @race.runs.where(:heat => @race.current_heat).order_by(:start => 'DESC').limit(3)
		@runs = @race.runs.where(:heat => @race.current_heat).order_by(:start => 'DESC')
		@run = Run.new
		@run.start = Time.now
  end

	def get_boat_class(bib)
		inx = bib[-2..-1] || str
		case inx.downcase
			when 'km'
				return "k1m"
			when 'cm'
				return "c1m"
			when 'kw'
				return "k1w"
			when 'cw'
				return "c1w"
			when 'cc'
				return "c2"
			when 'c2'
				return "c2"
			when 'k1'
				return "k1m"
			when 'c1'
				return "c1m"
			when 'oc'
				return "oc1"
			when 'oo'
				return "oc2"
			else
				return "zz"
		end
	end
  # POSt /races/1/start_run
	def start_run
		if !params['bib_box'].blank?
			@bib = params['bib_box']
		else
			@bib = params[:run][:bib]
		end

		if @bib.blank?
			@bib="#{Time.now}_zz"
		end
		@boat_class = get_boat_class(@bib)

		posted_runs = @race.runs.where(bib: @bib, boat_class: @boat_class, heat: @race.current_heat, start: nil)
		if !posted_runs.blank?
			@run = posted_runs.first
		else
			@run = Run.new
		end

		if @race.auto_start != true
			if params[:run][:start].blank?
				@run.start = Time.now.round_off(@race.round_start_interval)
			else
				@run.start = Time.parse(params[:run][:start]).round_off(@race.round_start_interval)
			end
		else
			if params[:run][:start].blank?
				@run.prestart = Time.now.round_off(@race.round_start_interval)
			else
				@run.prestart = Time.parse(params[:run][:start]).round_off(@race.round_start_interval)
			end
		end
		@run.bib = @bib
		#check for a run in this heat already
		if !@race.runs.where(bib: @bib, boat_class: @boat_class, heat: @race.current_heat ).blank?
			@run.heat = "#{@race.current_heat}_#{Time.now}"
		else
			@run.heat = @race.current_heat
		end
		if !@run.bib.blank?
			if @race.racers.where(bib: @run.bib).blank?
				@racer = Racer.new(:bib => @run.bib, :name => @run.bib, :boat_class => get_boat_class(@run.bib))
				@racer.order = @race.next_racer_order
				@race.racers << @racer
				@racer.save
			else
				@racer = @race.racers.find_by(bib: @run.bib)
			end
		end
		@run.boat_class = @racer.boat_class
		if @race.auto_start != true
			@run.status = "Started"
		else
			@run.status = "PreStarted"
		end
    respond_to do |format|
			if !@race.blank?
				@race.runs << @run
			end
			if !@racer.blank?
				@racer.runs << @run
			end
      if @run.save
        format.html { redirect_to start_run_form_race_path(@race), notice: 'Run was successfully created.' }
        #format.json { render :show, status: :created, location: @race }
				format.js {}
        format.json { render status: :created }
      else
        format.html { redirect_to start_run_form_race_path(@race), notice: 'Run could not be created.'}
        format.json { render json: @race.errors, status: :unprocessable_entity }
      end
    end

	end

	def finish_run_form
		@run = Run.new
		@run.finish = Time.now.strftime("%T")
	end

  # POSt /races/1/finish_run
	def finish_run
		@bib = params[:run][:bib]
		if @bib.blank?
			@bib="#{Time.now}_zz"
		end
		@boat_class = get_boat_class(@bib)
		@finish = params[:run][:finish]

		@run = nil
		if !@bib.blank? and !@finish.blank?
			posted_runs = @race.runs.where(bib: @bib, boat_class: @boat_class, heat: @race.current_heat)
			if !posted_runs.blank?
				@run = posted_runs.first
				if @run.finish.blank?
					@run = Run.find_by(bib: @bib, boat_class: @boat_class, heat:@race.current_heat)
					@run.finish = @finish
				else
					@run = Run.new
					if !@finish.blank?
						@run.finish = @finish
					end
					@run.bib = @bib
					@run.heat = "#{@race.current_heat}_#{Time.now}"
				end
			end
		end
		if @run.blank?
			@run = Run.new
			if !@finish.blank?
				@run.finish = @finish
			end
			@run.bib = @bib
			@run.heat = @race.current_heat
		end
		if @race.racers.where(bib: @run.bib).blank?
			unless @race.lock_racer_list_finish == true
				@racer = Racer.new(:bib => @run.bib, :name => @run.bib, :boat_class => get_boat_class(@run.bib))
				@racer.order = @race.next_racer_order
				@race.racers << @racer
				@racer.save
			end
		else
			@racer = @race.racers.where(bib: @run.bib).first
		end

		unless @racer.blank?
			@run.boat_class = @racer.boat_class
			@racer.runs << @run
		else 
			@run.boat_class = @boat_class
		end
		@run.status = "Finished"
		@race.runs << @run
		if @race.auto_sync == true
			auto_sync_finish(@run)
		end
    respond_to do |format|
      if @run.save
        format.html { redirect_to finish_run_form_race_path(@race), notice: 'Run was successfully finished.' }
        format.json { render :show, status: :created, location: @race }
      else
        format.html { redirect_to finish_run_form_race_path(@race), notice: message }
        format.json { render json: @race.errors, status: :unprocessable_entity }
      end
    end

	end

  # GET /races/1/edit
  def edit
  end

  # POST /races
  # POST /races.json
  def create
    @race = Race.new(race_params)

    respond_to do |format|
      if @race.save
        format.html { redirect_to @race, notice: 'Race was successfully created.' }
        format.json { render :show, status: :created, location: @race }
      else
        format.html { render :new }
        format.json { render json: @race.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /races/1
  # PATCH/PUT /races/1.json
  def update
    respond_to do |format|
      if @race.update(race_params)
        format.html { redirect_to @race, notice: 'Race was successfully updated.' }
        format.json { render :show, status: :ok, location: @race }
      else
        format.html { render :edit }
        format.json { render json: @race.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /racers/1/inline_update.json
  def inline_update

    respond_to do |format|
      if @race.update_attributes(race_params)
        format.html { redirect_to @race, notice: 'Race was successfully updated.' }
        format.json { render json: @race, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @race.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /races/1
  # DELETE /races/1.json
  def destroy
    @race.destroy
    respond_to do |format|
      format.html { redirect_to races_url, notice: 'Race was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

	def check_for_more_runs
		@last_run = @race.runs.order(:finish => :desc).first
		#@unfinished_runs = @race.runs.where(:finish => nil, :start.ne => nil, :heat => @race.current_heat).order_by(:start => 'asc')
		@unfinished_runs = @race.runs.where(:finish => nil, :start.ne => nil, :heat => @race.current_heat, :status => "Started").order_by(:start => 'asc')
		unless params[:last_finish].blank?
			@runs = @race.runs.where(:finish.gt => params[:last_finish]).order(:finish => :asc)
		else
			@runs = nil
		end
	end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_race
      @race = Race.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def race_params
      params.require(:race).permit(:name, :current_heat, :round_start_interval, :start_date, :lock_racer_list_finish, :auto_sync, :auto_start)
    end
end
