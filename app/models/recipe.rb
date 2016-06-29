class Recipe
  include Mongoid::Document
  field :name, type: String
  field :instructions, type: String
end
