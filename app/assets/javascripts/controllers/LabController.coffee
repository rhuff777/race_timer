controllers = angular.module('controllers')
controllers.controller("LabController", [ '$scope', '$routeParams', '$location', '$resource', 'poller',
  ($scope,$routeParams,$location,$resource, poller)->

    $scope.started = false
    $scope.polling = false
    $scope.status = null
    $scope.experimentPoller = null

    Experiment = $resource('/experiments/:expId', {expId: "@id", format: 'json' },
      {'launch': {
        url: '/experiments/:expId/launch',
        params: {expId: "@id", format: 'json' },
        method: 'POST'},
      'stop': {
        url: '/experiments/:expId/stop',
        params: {expId: "@id", format: 'json' },
        method: 'POST'},
      'complete': {
        url: '/experiments/:expId/complete',
        params: {expId: "@id", format: 'json' },
        method: 'POST'},
      'status': {
        url: '/experiments/:expId/status',
        params: {expId: "@id", format: 'json' },
        method: 'GET'}
      },
    )

    # can use this for status calls too
    Experiment.get({expId: $routeParams.id},
      ( (exp)-> 
        $scope.experiment = exp
      ),
      ( (httpResponse) -> $scope.experiment = null)
    )

    $scope.get_prompt_status = (promptName)->
      Experiment.status({expId: $routeParams.id, promptId: promptName},{},
        ( (status)-> 
          $scope.status = status
        ),
        ( (httpResponse) -> $scope.status = null)
      )

    $scope.get_status = ()->
      Experiment.get({expId: $routeParams.id},
        ( (exp)-> 
          $scope.experiment = exp
        ),
        ( (httpResponse) -> $scope.experiment = null)
      )

    $scope.start_stop = ()->
      if $scope.started == false
        $scope.started = true
        $scope.experiment.status = "Connecting"
        Experiment.launch({expId: $routeParams.id},{},
          ( (exp)-> 
            $scope.experiment = exp
          ),
          ( (httpResponse) -> $scope.started = false)
        )
        $scope.pollExperiment()
      else
        $scope.started = false
        $scope.experiment.status = "Stopped"
        Experiment.stop({expId: $routeParams.id},{},
          ( (exp)-> 
            $scope.experiment = exp
          ),
          ( (httpResponse) -> )
        )
        $scope.stopPollingExperiment()

    $scope.pollExperiment = ()->
      $scope.polling = true
      if $scope.experimentPoller == null
        $scope.experimentPoller = poller.get(Experiment, {action: 'get', delay: 10000, argumentsArray: [{expId: $routeParams.id}]})
        $scope.experimentPoller.promise.then(null, null, (result) ->
          $scope.experiment = result
        )
      else
        $scope.experimentPoller.restart()

    $scope.stopPollingExperiment = ()->
      $scope.polling = false
      if $scope.experimentPoller != null
        $scope.experimentPoller.stop()
 
    $scope.start_stop_polling = ()->
      if $scope.polling == false
        $scope.polling = true
        $scope.pollExperiment()
      else
        $scope.polling = false
        $scope.stopPollingExperiment()

    $scope.complete_experiment = ()->
       $scope.started = false
       $scope.stopPollingExperiment()
       Experiment.complete({expId: $routeParams.id},{},
       ( (exp)-> 
          $scope.experiment = exp
       ),
        ( (httpResponse) -> )
       )

])

