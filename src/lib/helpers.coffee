helpers =
# Routing Helpers
# ---------------

# Returns the url for a named route and any params.
  reverse: (criteria, params, query) ->
    Backbone.trigger 'router:reverse', criteria, params, query

# Redirects to URL, route name or controller and action pair.
  redirectTo: (pathDesc, params, options) ->
    Backbone.trigger 'router:route', pathDesc, params, options