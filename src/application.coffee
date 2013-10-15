class Mildred.Application
  # Borrow the `extend` method from a dear friend.
  @extend = Backbone.Model.extend

  # Site-wide title that is mapped to HTML `title` tag.
  title: ''

  # Core Object Instantiation
  # -------------------------

  # The application instantiates three **core modules**:
  dispatcher: null
  layout: null
  router: null
  composer: null
  started: false

  constructor: (options = {}) ->
    @initialize options

  initialize: (options = {}) ->
    # Check if app is already started.
    if @started
      throw new Error 'Application#initialize: App was already started'

    # Set template function globally
    if typeof options.templateFunction is 'function'
      Mildred.templateFunction = options.templateFunction

    # Initialize core components.
    # ---------------------------

    # Register all routes.
    # You might pass Router/History options as the second parameter.
    # Mildred enables pushState per default and Backbone uses / as
    # the root per default. You might change that in the options
    # if necessary:
    # @initRouter routes, pushState: false, root: '/subdir/'
    @initRouter options.routes, options

    # Dispatcher listens for routing events and initialises controllers.
    @initDispatcher options

    # Layout listens for click events & delegates internal links to router.
    @initLayout options

    # Composer grants the ability for views and stuff to be persisted.
    @initComposer options

    # Start the application.
    @start()

  # **Mildred.Dispatcher** sits between the router and controllers to listen
  # for routing events. When they occur, Mildred.Dispatcher loads the target
  # controller module and instantiates it before invoking the target action.
  # Any previously active controller is automatically disposed.

  initDispatcher: (options) ->
    @dispatcher = new Mildred.Dispatcher options

  # **Mildred.Layout** is the top-level application view. It *does not
  # inherit* from Mildred.View but borrows some of its functionalities. It
  # is tied to the document dom element and registers application-wide
  # events, such as internal links. And mainly, when a new controller is
  # activated, Mildred.Layout is responsible for changing the main view to
  # the view of the new controller.

  initLayout: (options = {}) ->
    options.title ?= @title
    @layout = new Mildred.Layout options

  initComposer: (options = {}) ->
    @composer = new Mildred.Composer options

  # **Mildred.Router** is responsible for observing URL changes. The router
  # is a replacement for Backbone.Router and *does not inherit from it*
  # directly. It's a different implementation with several advantages over
  # the standard router provided by Backbone. The router is typically
  # initialized by passing the function returned by **routes.coffee**.

  initRouter: (routes, options) ->
    # Save the reference for testing introspection only.
    # Modules should communicate with each other via **publish/subscribe**.
    @router = new Mildred.Router options

    # Register any provided routes.
    routes? @router.match

  # Can be customized when overridden.
  start: ->
    # After registering the routes, start **Backbone.history**.
    @router.startHistory()

    # Mark app as initialized.
    @started = true

    # Freeze the application instance to prevent further changes.
    Object.freeze? this

  # Disposal
  # --------
  disposed: false

  dispose: ->
    # Am I already disposed?
    return if @disposed

    properties = ['dispatcher', 'layout', 'router', 'composer']
    for prop in properties when this[prop]?
      this[prop].dispose()
      delete this[prop]

    @disposed = true