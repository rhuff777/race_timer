class RecipesController < ApplicationController
  def index
    @recipes = if params[:keywords]
      Recipe.all
      #Recipe.where(name: /"%#{params[:keywords]}%"/)
      #Recipe.where('name ilike ?',"%#{params[:keywords]}%")
    else
      []
    end
  end
end
