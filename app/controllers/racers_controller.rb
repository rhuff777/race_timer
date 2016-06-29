class RacersController < ApplicationController
  before_action :set_racer, only: [:show, :edit, :update, :destroy, :inline_update]
  before_action :set_race, only: [:index, :new, :import, :do_import]

  # GET /racers
  # GET /racers.json
  def index
    #@racers = @race.racers.all
    @racers = @race.racers.all.order_by(:order => "asc")
  end

  # GET /racers/1
  # GET /racers/1.json
  def show
  end

	def import
		@races = Race.all
	end

	def do_import
  	redirect_to race_racers_path(:race_id => racer_params[:race_id]), notice: 'Racer was successfully created.'
	end

  # GET /racers/new
  def new
    @racer = Racer.new
		@racer.race_id = @race.id
		@racer.order = @race.next_racer_order
  end

  # GET /racers/1/edit
  def edit
  end

  # POST /racers
  # POST /racers.json
  def create
    @racer = Racer.new(racer_params)
		@race = Race.find(racer_params[:race_id])
		@racer.race_id = nil
    respond_to do |format|
      @race.racers << @racer
      if @racer.save
        #format.html { redirect_to @racer, notice: 'Racer was successfully created.' }
        format.html { redirect_to racers_path(:race_id => racer_params[:race_id]), notice: 'Racer was successfully created.' }
        format.json { render :show, status: :created, location: @racer }
      else
        format.html { render :new }
        format.json { render json: @racer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /racers/1
  # PATCH/PUT /racers/1.json
  def update
    respond_to do |format|
      if @racer.update(racer_params)
        format.html { redirect_to @racer, notice: 'Racer was successfully updated.' }
        format.json { render :show, status: :ok, location: @racer }
      else
        format.html { render :edit }
        format.json { render json: @racer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /racers/1/inline_update.json
  def inline_update

    respond_to do |format|
      if @racer.update_attributes(racer_params)
        format.html { redirect_to @racer, notice: 'Racer was successfully updated.' }
        format.json { render json: @racer, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @racer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /racers/1
  # DELETE /racers/1.json
  def destroy
    @racer.destroy
    respond_to do |format|
      format.html { redirect_to race_racers_url(@race), notice: 'Racer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_racer
      @racer = Racer.find(params[:id])
			@race = @racer.race_id
    end

    def set_race
    	@race = Race.find(params[:race_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def racer_params
      params.require(:racer).permit(:name, :bib, :order, :boat_class, :age_class, :race_id)
    end
end
