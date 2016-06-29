class RunsController < ApplicationController
  before_action :set_run, only: [:show, :edit, :update, :destroy, :reheat, :dns, :dnf, :inline_update, :inline_update_racer, :inline_destroy, :unfinish]
  before_action :set_race, only: [:index, :new]

  # GET /runs
  # GET /runs.json
  def index
    @runs = @race.runs.all.order_by(:start => 'asc')
  end

  # GET /runs/1
  # GET /runs/1.json
  def show
  end

  # GET /runs/new
  def new
    @run = Run.new
		@run.race_id = @race.id
  end

  # GET /runs/1/edit
  def edit
  end

  # POST /runs
  # POST /runs.json
  def create
    @run = Run.new(run_params)
		@race = Race.find(run_params[:race_id])
		@run.race_id = nil
		@run.heat = @race.current_heat
		if !@run.bib.blank? and !@run.boat_class.blank?
			if @race.racers.where(bib: @run.bib, boat_class: @run.boat_class).blank?
				@racer = Racer.new(:bib => @run.bib, :boat_class => @run.boat_class)
				@racer.save
			else
				@racer = @race.racers.find_by(bib: @run.bib, boat_class: @run.boat_class)
			end
		end

    respond_to do |format|
			if !@race.blank?
				@race.runs << @run
			end
			if !@racer.blank?
				@racer.runs << @run
			end
      if @run.save
        format.html { redirect_to @run, notice: 'Run was successfully created.' }
        format.json { render :show, status: :created, location: @run }
      else
        format.html { render :new }
        format.json { render json: @run.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /runs/1
  # PATCH/PUT /runs/1.json
  def update
		#does it have only a start
		posted_run = nil
		if !run_params[:start_string].blank? and run_params[:finish_string].blank?
			posted_run = @race.runs.where(:bib =>run_params[:bib], :boat_class => run_params[:boat_class], :heat => run_params[:heat], :start => nil, :finish.ne => nil).first
		else 		
			#does it have only a finish
			if !run_params[:finish_string].blank? and run_params[:start_string].blank?
				posted_run = @race.runs.where(:bib => run_params[:bib], :boat_class => run_params[:boat_class], :heat => run_params[:heat], :finish => nil, :start.ne => nil).first
			end
		end

    respond_to do |format|
      if @run.update(run_params)
				if !posted_run.blank?
					if !posted_run.finish.blank?
						@run.finish = posted_run.finish
						@run.save
					else
						if !posted_run.start.blank?
							@run.start = posted_run.start
							@run.save
						end
					end
					posted_run.destroy
				end
        format.html { redirect_to @run, notice: 'Run was successfully updated.' }
        format.json { render :show, status: :ok, location: @run }
      else
        format.html { render :edit }
        format.json { render json: @run.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /runs/1/inline_update.json
  def inline_update

    respond_to do |format|
      if @run.update_attributes(run_params)
        format.html { redirect_to @run, notice: 'Run was successfully updated.' }
        format.json { render json: @run, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @run.errors, status: :unprocessable_entity }
      end
    end
  end

  def inline_update_racer
		unless params['racer']['id'].blank?
			@racer = Racer.find(params['racer']['id'])
			unless @racer.blank?
				srun = @racer.runs.find_by(:heat => @run.heat)
				if !srun.blank? and !srun.start.blank? and srun.id != @run.id 
					@run.start = srun.start
					srun.destroy
				end
				@run.bib = @racer.bib
				@run.boat_class = @racer.boat_class
				@racer.runs << @run
			end
		end
		unless @run.racer.blank?
			foo = @run.as_json
			foo["name"] = @run.racer.name
			@run = foo
		end	
    respond_to do |format|
        format.html { redirect_to @run, notice: 'Run was successfully updated.' }
        format.json { render json: @run, status: :ok }
    end
  end


  # DELETE /runs/1
  # DELETE /runs/1.json
  def destroy
    @run.destroy
		@runs = @race.runs.where(:heat => @race.current_heat).order_by(:start => 'DESC').limit(3)
    respond_to do |format|
      format.html { redirect_to race_runs_url(@race), notice: 'Run was successfully destroyed.' }
			format.js { }
      format.json { head :no_content }
    end
  end

  def dns
    @run.status = "DNS"
		@run.save
		@runs = @race.runs.where(:heat => @race.current_heat).order_by(:start => 'DESC').limit(3)
    respond_to do |format|
      format.html { redirect_to race_runs_url(@race), notice: 'Run was successfully destroyed.' }
			format.js { render :destroy}
      format.json { head :no_content }
    end
  end

  def dnf
    @run.status = "DNF"
		@run.save
		@runs = @race.runs.where(:heat => @race.current_heat).order_by(:start => 'DESC').limit(3)
    respond_to do |format|
      format.html { redirect_to race_runs_url(@race), notice: 'Run was successfully destroyed.' }
			format.js { render :destroy}
      format.json { head :no_content }
    end
  end

	def reheat
		parts =  @run.heat.split("_")
		if !parts.blank?
			@run.heat = parts[0]
		end
    respond_to do |format|
	    if @run.save
  	    format.html { redirect_to race_runs_url(@race), notice: 'Run was successfully reheated.' }
    	  format.json { render :show, status: :created, location: @run }
	    else
  	    format.html { redirect_to race_runs_url(@race), notice: 'Run was not reheated.' }
    	  format.json { render json: @run.errors, status: :unprocessable_entity }
	    end
		end
	end

	def inline_destroy
		@id = @run.id
    @run.destroy
	end

	def unfinish
		@finish = @run.finish
		@run.finish = nil
		@run.raw_time = nil
		@run.save
		@race = @run.race
		@bib="#{Time.now}_zz"
		@boat_class = "zz"
		@nrun = Run.new
		if !@finish.blank?
			@nrun.finish = @finish
		end
		@nrun.bib = @bib
		@nrun.heat = "#{@race.current_heat}"
		@nrun.status = "Finished"
		@nrun.boat_class = @boat_class
		@race.runs << @nrun
		@nrun.save
		redirect_to finishes_race_url(@race), notice: "Run was unfinished successfully"
	end
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_run
      @run = Run.find(params[:id])
			@race = @run.race
    end

    def set_race
    	@race = Race.find(params[:race_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def run_params
      params.require(:run).permit(:start_string, :finish_string, :start, :finish, :heat, :raw_time, :total_penalties, :score, :bib, :boat_class, :race_id, :status)
    end
end
