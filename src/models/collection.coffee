class Mildred.Collection extends Backbone.Collection
  # Use the Mildred model per default, not Backbone.Model.
  model: Mildred.Model

  # Serializes collection.
  serialize: ->
    @map Mildred.utils.serialize

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Fire an event to notify associated views.
    @trigger 'dispose', this

    # Empty the list silently, but do not dispose all models since
    # they might be referenced elsewhere.
    @reset [], silent: true

    # Unbind all referenced handlers.
    @stopListening()

    # Remove all event handlers on this module.
    @off()

    # Remove model constructor reference, internal model lists
    # and event handlers.
    properties = [
      'model',
      'models', '_byId', '_byCid',
      '_callbacks'
    ]
    delete this[prop] for prop in properties

    # Finished.
    @disposed = true