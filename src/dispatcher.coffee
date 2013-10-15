class Mildred.Dispatcher
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # The previous route information.
  # This object contains the controller name, action, path, and name (if any).
  previousRoute: null

  # The current controller, route information, and parameters.
  # The current route object contains the same information as previous.
  currentController: null
  currentRoute: null
  currentParams: null

  constructor: ->
    @initialize arguments...

  initialize: (options = {}) ->
    @controllers = options.controllers

    # Listen to global events.
    Backbone.on 'router:match', @dispatch, this

  # Controller management.
  # Starting and disposing controllers.
  # ----------------------------------

  # The standard flow is:
  #
  # 1. Test if it’s a new controller/action with new params
  # 1. Hide the previous view
  # 2. Dispose the previous controller
  # 3. Instantiate the new controller, call the controller action
  # 4. Show the new view
  #
  dispatch: (route, params, options) ->
    # Clone params and options so the original objects remain untouched.
    params = if params then _.clone(params) else {}
    options = if options then _.clone(options) else {}

    # Whether to update the URL after controller startup.
    # Default to true unless explicitly set to false.
    options.changeURL = true unless options.changeURL is false

    # Whether to force the controller startup even
    # if current and new controllers and params match
    # Default to false unless explicitly set to true.
    options.forceStartup = false unless options.forceStartup is true

    # Stop if the desired controller/action is already active
    # with the same params.
    return if not options.forceStartup and
    @currentRoute?.controller is route.controller and
    @currentRoute?.action is route.action and
    _.isEqual @currentParams, params

    # Fetch the new controller, if any, then go on.
    if @controllers?
      controller = @getControllerByName(route.controller)
      @runController controller, route, params, options

  # gets the proper controller from the controllers list
  # by the name provided at the router match
  getControllerByName: (name) ->
    for controller in @controllers
      # clean up the "Controller" string from the name
      controller_string_place = controller.name.toUpperCase().indexOf("CONTROLLER")
      if controller_string_place > -1
        if controller.name.toUpperCase().indexOf("_CONTROLLER") > -1
          cont_name = controller.name.toUpperCase().slice(0, -11)
        else
          cont_name = controller.name.toUpperCase().slice(0, -10)
      else
        cont_name = controller.name.toUpperCase()

      if cont_name == name.toUpperCase()
        return controller

  runController: (controller, route, params, options) ->
    @previousRoute = @currentRoute
    @currentRoute = _.extend {}, route, {previous: Mildred.utils.beget(@previousRoute)}
    controller = new controller params, @currentRoute, options
    @executeBeforeAction controller, @currentRoute, params, options

  # Executes controller action.
  executeAction: (controller, route, params, options) ->
    # Dispose the previous controller.
    if @currentController
      # Notify the rest of the world beforehand.
      Backbone.trigger 'beforeControllerDispose', @currentController

      # Passing new parameters that the action method will receive.
      @currentController.dispose params, route, options

    # Save the new controller and its parameters.
    @currentController = controller
    @currentParams = params

    # Call the controller action with params and options.
    controller[route.action] params, route, options

    # Stop if the action triggered a redirect.
    return if controller.redirected

    # Adjust the URL.
    @adjustURL route, params, options

    # We're done! Spread the word!
    Backbone.trigger 'dispatcher:dispatch', @currentController,
      params, route, options

  # Executes before action filterer.
  executeBeforeAction: (controller, route, params, options) ->
    before = controller.beforeAction

    executeAction = =>
      if controller.redirected or @currentRoute and route isnt @currentRoute
        controller.dispose()
        return
      @executeAction controller, route, params, options

    unless before
      executeAction()
      return

    # Throw deprecation warning.
    if typeof before isnt 'function'
      throw new TypeError 'Controller#beforeAction: function expected. ' +
      'Old object-like form is not supported.'

    # Execute action in controller context.
    promise = controller.beforeAction params, route, options
    if promise and promise.then
      promise.then executeAction
    else
      executeAction()

  # Change the URL to the new controller using the router.
  adjustURL: (route, params, options) ->
    return unless route.path?

    # Tell the router to actually change the current URL.
    url = route.path + if route.query then "?#{route.query}" else ""
    Backbone.trigger 'router:changeURL', url, options if options.changeURL

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # turn off the events
    @off

    @disposed = true