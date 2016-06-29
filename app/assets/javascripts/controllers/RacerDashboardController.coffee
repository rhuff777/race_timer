controllers = angular.module('controllers')
controllers.controller("RacerDashboardController", [ '$scope', '$routeParams', '$location', '$resource',
  ($scope,$routeParams,$location,$resource)->

    Racers = $resource('/races/:race_id', {race_id: "@race_id", format: 'json' },
      {'all_racers': {
        url: '/races/:race_id/racers',
        params: {race_id: "@race_id", format: 'json' },
        method: 'GET', isArray: true},
      'save_all_racers': {
        url: '/races/:race_id/save_all_racers',
        params: {race_id: "@race_id", format: 'json' },
        method: 'POST', isArray: true}
      }
    )
    Racers.all_racers({race_id: $routeParams.race_id},{},
      ( (racers)-> 
        $scope.racers = racers
      ),
      ( (httpResponse) -> $scope.racers = null)
    )

    $scope.models = {selected: null,lists: {"A": []}}

    for i in [1..3]
      $scope.models.lists.A.push({label: "Item A" + i})

    #$scope.$watch('models', (model) ->
    #  $scope.modelAsJson = angular.toJson(model, true)
    #, true)

    $scope.$watch('racers', (model) ->
      if model
        #model.forEach (m, i, array) ->
        #  m.order = i+1
        #$scope.racers.$save
        Racers.save_all_racers($scope.racers,
          ( (resp)-> 
            $scope.foo = 'bar'
          ),
          ( (httpResponse) -> $scope.foo = null)
        )



      $scope.modelAsJson = angular.toJson(model, true)
    , true)


    $scope.test = "foobar"
])

