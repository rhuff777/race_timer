recipe = angular.module('recipe',[
  'templates',
  'ngRoute',
  'ngResource',
  'controllers',
])

recipe.config([ '$routeProvider',
  ($routeProvider)->
    $routeProvider
      .when('/',
        templateUrl: "recipe.html"
        controller: 'RecipesController'
      )
])

racer_dashboard = angular.module('racer_dashboard',[
  'templates',
  'ngRoute',
  'ngResource',
  'dndLists',
  'ui.grid',
  'controllers',
])

racer_dashboard.config([ '$routeProvider',
  ($routeProvider)->
    $routeProvider
      .when('/:race_id',
        templateUrl: "racer_dashboard.html"
        controller: 'RacerDashboardController'
      )
])

controllers = angular.module('controllers',[])

