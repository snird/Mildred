# Shortcut to access the DOM manipulation library.
$ = Backbone.$

# Function bind shortcut.
bind = do ->
  if Function::bind
    (item, ctx) -> item.bind ctx
  else if _.bind
    _.bind

class Mildred.View extends Backbone.View

  # Automatic rendering
  # -------------------

  # Flag whether to render the view automatically on initialization.
  # As an alternative you might pass a `render` option to the constructor.
  autoRender: false

  # Flag whether to attach the view automatically on render.
  autoAttach: true

  # Automatic inserting into DOM
  # ----------------------------

  # View container element.
  # Set this property in a derived class to specify the container element.
  # Normally this is a selector string but it might also be an element or
  # jQuery object.
  # The view is automatically inserted into the container when it’s rendered.
  # As an alternative you might pass a `container` option to the constructor.
  container: null

  # Method which is used for adding the view to the DOM
  # Like jQuery’s `html`, `prepend`, `append`, `after`, `before` etc.
  containerMethod: 'append'

  # A view is `stale` when it has been previously composed by the last
  # route but has not yet been composed by the current route.
  stale: false

  # Specifies if current element should be kept in DOM after disposal.
  keepElement: false

  # Subviews
  # --------

  # List of subviews.
  subviews: null
  subviewsByName: null

  # Initialization
  # --------------

  # List of options that will be picked from constructor.
  # Easy to extend: `optionNames: View::optionNames.concat ['template']`
  optionNames: [
    'autoAttach', 'autoRender',
    'container', 'containerMethod'
  ]

  constructor: (options) ->
    # Copy some options to instance properties.
    if options
      for optName, optValue of options when optName in @optionNames
        this[optName] = optValue

    # Wrap `render` so `attach` is called afterwards.
    # Enclose the original function.
    render = @render
    # Create the wrapper method.
    @render = =>
      # Stop if the instance was already disposed.
      return false if @disposed
      # Call the original method.
      render.apply this, arguments
      # Attach to DOM.
      @attach arguments... if @autoAttach
      # Return the view.
      this

    # Initialize subviews collections.
    @subviews = []
    @subviewsByName = {}

    # Call Backbone’s constructor.
    super

    # Set up declarative bindings after `initialize` has been called
    # so initialize may set model/collection and create or bind methods.
    @delegateListeners()

    # Listen for disposal of the model or collection.
    # If the model is disposed, automatically dispose the associated view.
    @listenTo @model, 'dispose', @dispose if @model
    if @collection
      @listenTo @collection, 'dispose', (subject) =>
        @dispose() if not subject or subject is @collection

		# Wrap render method with after and before callbacks
		@render = _.wrap(@render, (render) =>
			@beforeRender()
			render()
			@afterRender()
		)

    # Render automatically if set by options or instance property.
    @render() if @autoRender

  # User input event handling
  # -------------------------

  # Event handling using event delegation
  # Register a handler for a specific event type
  # For the whole view:
  #   delegate(eventName, handler)
  #   e.g.
  #   @delegate('click', @clicked)
  # For an element in the passing a selector:
  #   delegate(eventName, selector, handler)
  #   e.g.
  #   @delegate('click', 'button.confirm', @confirm)
  delegate: (eventName, second, third) ->
    if typeof eventName isnt 'string'
      throw new TypeError 'View#delegate: first argument must be a string'

    if arguments.length is 2
      handler = second
    else if arguments.length is 3
      selector = second
      if typeof selector isnt 'string'
        throw new TypeError 'View#delegate: ' +
          'second argument must be a string'
      handler = third
    else
      throw new TypeError 'View#delegate: ' +
        'only two or three arguments are allowed'

    if typeof handler isnt 'function'
      throw new TypeError 'View#delegate: ' +
        'handler argument must be function'

    # Add an event namespace, bind handler it to view.
    list = ("#{event}.delegate#{@cid}" for event in eventName.split ' ')
    events = list.join(' ')
    bound = bind handler, this
    @$el.on events, (selector or null), bound

    # Return the bound handler.
    bound

  # Copy of original Backbone method without `undelegateEvents` call.
  _delegateEvents: (events) ->
    for key, value of events
      handler = if typeof value is 'function' then value else this[value]
      throw new Error "Method '#{handler}' does not exist" unless handler
      match = key.match /^(\S+)\s*(.*)$/
      eventName = "#{match[1]}.delegateEvents#{@cid}"
      selector = match[2]
      bound = bind handler, this
      @$el.on eventName, (selector or null), bound
    return

  # Override Backbones method to combine the events
  # of the parent view if it exists.
  delegateEvents: (events) ->
    @undelegateEvents()
    if events
      @_delegateEvents events
      return
    return unless @events
    # Call _delegateEvents for all superclasses’ `events`.
    for classEvents in Mildred.utils.getAllPropertyVersions this, 'events'
      if typeof classEvents is 'function'
        throw new TypeError 'View#delegateEvents: functions are not supported'
      @_delegateEvents classEvents
    return

  # Remove all handlers registered with @delegate.
  undelegate: (eventName, second, third) ->
    if eventName
      if typeof eventName isnt 'string'
        throw new TypeError 'View#undelegate: first argument must be a string'

      if arguments.length is 2
        if typeof second is 'string'
          selector = second
        else
          handler = second
      else if arguments.length is 3
        selector = second
        if typeof selector isnt 'string'
          throw new TypeError 'View#undelegate: ' +
            'second argument must be a string'
        handler = third

      list = ("#{event}.delegate#{@cid}" for event in eventName.split ' ')
      events = list.join(' ')
      @$el.off events, (selector or null)
    else
      @$el.off ".delegate#{@cid}"

  # Handle declarative event bindings from `listen`
  delegateListeners: ->
    return unless @listen

    # Walk all `listen` hashes in the prototype chain.
    for version in Mildred.utils.getAllPropertyVersions this, 'listen'
      for key, method of version
        # Get the method, ensure it is a function.
        if typeof method isnt 'function'
          method = this[method]
        if typeof method isnt 'function'
          throw new Error 'View#delegateListeners: ' +
            "#{method} must be function"

        # Split event name and target.
        [eventName, target] = key.split ' '
        @delegateListener eventName, target, method

    return

  delegateListener: (eventName, target, callback) ->
    if target in ['model', 'collection']
      prop = this[target]
      @listenTo prop, eventName, callback if prop
    else if not target
      @on eventName, callback, this

    return

  # Subviews
  # --------

  # Getting or adding a subview.
  subview: (name, view) ->
    # Initialize subviews collections if they don’t exist yet.
    subviews = @subviews
    byName = @subviewsByName

    if name and view
      # Add the subview, ensure it’s unique.
      @removeSubview name
      subviews.push view
      byName[name] = view
      view
    else if name
      # Get and return the subview by the given name.
      byName[name]

  # Removing a subview.
  removeSubview: (nameOrView) ->
    return unless nameOrView
    subviews = @subviews
    byName = @subviewsByName

    if typeof nameOrView is 'string'
      # Name given, search for a subview by name.
      name = nameOrView
      view = byName[name]
    else
      # View instance given, search for the corresponding name.
      view = nameOrView
      for otherName, otherView of byName
        if view is otherView
          name = otherName
          break

    # Break if no view and name were found.
    return unless name and view and view.dispose

    # Dispose the view.
    view.dispose()

    # Remove the subview from the lists.
    index = Mildred.utils.indexOf subviews, view
    subviews.splice index, 1 if index isnt -1
    delete byName[name]

  # Rendering
  # ---------

  # Get the model/collection data for the templating function
  # Uses optimized Chaplin serialization if available.
  getTemplateData: ->
    data = if @model
      Mildred.utils.serialize @model
    else if @collection
      {items: Mildred.utils.serialize(@collection), length: @collection.length}
    else
      {}

    source = @model or @collection
    if source
      # If the model/collection is a SyncMachine, add a `synced` flag,
      # but only if it’s not present yet.
      if typeof source.isSynced is 'function' and not ('synced' of data)
        data.synced = source.isSynced()

    data

  # Returns the compiled template function.
  getTemplateFunction: ->
    if _.isFunction Mildred.templateFunction
      return Mildred.templateFunction
    _.template

  # Main render function.
  # This method is bound to the instance in the constructor (see above)
  render: ->
    # Do not render if the object was disposed
    # (render might be called as an event handler which wasn’t
    # removed correctly).
    return false if @disposed

    templateFunc = @getTemplateFunction()

    # populate the template function with the view template string
    templateRender = templateFunc @template

    # Call the template function passing the template data.
    html = templateRender @getTemplateData()

    # Replace HTML
    @$el.html html

    # Return the view.
    this

	# Default void callbacks for before and after rendering
	# The key different between `afterRender` to `attach` method is attach 
	# executed only once after initializing the view and not after each render.
	beforeRender: ->
	afterRender: ->

  # This method is called after a specific `render` of a derived class.
  attach: ->
    # Automatically append to DOM if the container element is set.
    if @container and not document.body.contains @el
      $(@container)[@containerMethod] @el
      # Trigger an event.
      @trigger 'addedToDOM'

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Dispose subviews.
    subview.dispose() for subview in @subviews

    # Remove all event handlers on this module.
    @off()

    # Check if view should be removed from DOM.
    if @keepElement
      # Unsubscribe from all DOM events.
      @undelegateEvents()
      @undelegate()
      # Unbind all referenced handlers.
      @stopListening()
    else
      if @container
        $(@container).empty()
      else
        # Remove the topmost element from DOM. This also removes all event
        # handlers from the element and all its children.
        @remove()

    # Remove element references, options,
    # model/collection references and subview lists.
    properties = [
      'el', '$el',
      'options', 'model', 'collection',
      'subviews', 'subviewsByName',
      '_callbacks'
    ]
    delete this[prop] for prop in properties

    # Finished.
    @disposed = true