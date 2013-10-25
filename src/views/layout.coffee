class Mildred.Layout extends Mildred.View
  # Bind to document body by default.
  el: 'body'

  # Override default view behavior, we don’t want document.body to be removed.
  keepElement: true

  # The site title used in the document title.
  # This should be set in your app-specific Application class
  # and passed as an option.
  title: ''

  listen:
    'beforeControllerDispose mediator': 'scroll'

  constructor: (options = {}) ->
    @title = options.title
    @settings = _.defaults options,
      titleTemplate: _.template(
        "<% if (subtitle) { %><%= subtitle %> \u2013 <% } %><%= title %>"
      )
      openExternalToBlank: false
      routeLinks: 'a, .go-to'
      skipRouting: '.noscript'
    # Per default, jump to the top of the page.
      scrollTo: [0, 0]

    Backbone.on 'adjustTitle', @adjustTitle, this

    super

    # Set the app link routing.
    @startLinkRouting() if @settings.routeLinks

  # Controller startup and disposal
  # -------------------------------

  # Handler for the global beforeControllerDispose event.
  scroll: (controller) ->
    # Reset the scroll position.
    position = @settings.scrollTo
    if position
      window.scrollTo position[0], position[1]

  # Handler for the global dispatcher:dispatch event.
  # Change the document title to match the new controller.
  # Get the title from the title property of the current controller.
  adjustTitle: (subtitle = '') ->
    title = @settings.titleTemplate {@title, subtitle}
    document.title = title
    title

  # Automatic routing of internal links
  # -----------------------------------

  startLinkRouting: ->
    route = @settings.routeLinks
    @$el.on 'click', route, @openLink if route

  stopLinkRouting: ->
    route = @settings.routeLinks
    @$el.off 'click', route if route

  isExternalLink: (link) ->
    link.target is '_blank' or
    link.rel is 'external' or
    link.protocol not in ['http:', 'https:', 'file:'] or
    link.hostname not in [location.hostname, '']

  # Handle all clicks on A elements and try to route them internally.
  openLink: (event) =>
    return if Mildred.utils.modifierKeyPressed(event)

    el = event.currentTarget
    $el = $(el)
    isAnchor = el.nodeName is 'A'

    # Get the href and perform checks on it.
    href = $el.attr('href') or $el.data('href') or null

    # Basic href checks.
    return if not href? or
      # Technically an empty string is a valid relative URL
      # but it doesn’t make sense to route it.
      href is '' or
      # Exclude fragment links.
      href.charAt(0) is '#'

    # Apply skipRouting option.
    skipRouting = @settings.skipRouting
    type = typeof skipRouting
    return if type is 'function' and not skipRouting(href, el) or
      type is 'string' and $el.is skipRouting

    # Handle external links.
    external = isAnchor and @isExternalLink el
    if external
      if @settings.openExternalToBlank
        # Open external links normally in a new tab.
        event.preventDefault()
        window.open href
      return

    # Pass to the router, try to route the path internally.
    Mildred.helpers.redirectTo url: href

    # Prevent default handling if the URL could be routed.
    event.preventDefault()
    return

  # Disposal
  # --------

  dispose: ->
    return if @disposed

    # Stop routing links.
    @stopLinkRouting()

    # Remove all regions and document title setting.
    delete this[prop] for prop in ['title', 'route']

    @off

    super
