class Mildred.Controller
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin Backbone events.
  _.extend @prototype, Backbone.Events

  view: null

  # Internal flag which stores whether `redirectTo`
  # was called in the current action.
  redirected: false

  constructor: ->
    @initialize arguments...

  initialize: ->
    # Empty per default.

  beforeAction: ->
    # Empty per default.

    # Change document title.
  adjustTitle: (subtitle) ->
    Backbone.trigger 'adjustTitle', subtitle

  # Composer
  # --------

  # Convenience method to publish the `!composer:compose` event. See the
  # composer for information on parameters, etc.
  compose: (name) ->
    method = if arguments.length is 1 then 'retrieve' else 'compose'
    Backbone.trigger "composer:#{method}", arguments...

  # Redirection
  # -----------

  # Redirect to URL.
  redirectTo: (pathDesc, params, options) ->
    @redirected = true
    helpers.redirectTo pathDesc, params, options

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Dispose and delete all members which are disposable.
    for own prop, obj of this when obj and typeof obj.dispose is 'function'
      obj.dispose()
      delete this[prop]

    # Unbind handlers of global events.
    @off()

    # Unbind all referenced handlers.
    @stopListening()

    # Finished.
    @disposed = true