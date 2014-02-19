describe 'Layout', ->
  # Initialize shared variables
  layout = testController = router = null

  createLink = (attributes) ->
    attributes = if attributes then _.clone(attributes) else {}
    # Yes, this is ugly. We’re doing it because IE8-10 reports an incorrect
    # protocol if the href attribute is set programatically.
    if attributes.href?
      if attributes.class?
        attributes.class += ' go-to'
      div = document.createElement 'div'
      div.innerHTML = "<a href='#{attributes.href}' class='go-to'>Hello World</a>"
      link = div.firstChild
      attributes = _.omit attributes, 'href'
      $link = $(link)
    else
      $link = $(document.createElement 'a')
    $link.attr attributes

  expectWasRouted = (linkAttributes) ->
    stub = sinon.spy()
    Backbone.on 'router:route', stub
    createLink(linkAttributes).appendTo(document.body).click().remove()
    expect(stub).was.calledOnce()
    [passedPath] = stub.firstCall.args
    expect(passedPath).to.eql url: linkAttributes.href
    Backbone.off '!router:route', stub
    stub

  expectWasNotRouted = (linkAttributes) ->
    spy = sinon.spy()
    Backbone.on 'router:route', spy
    createLink(linkAttributes).appendTo(document.body).click().remove()
    expect(spy).was.notCalled()
    Backbone.off '!router:route', spy
    spy

  beforeEach ->
    # Create the layout
    layout = new Mildred.Layout title: 'Test Site Title'

    # Create a test controller
    testController = new Mildred.Controller()
    testController.view = new Mildred.View()
    testController.title = 'Test Controller Title'

  afterEach ->
    testController.dispose()
    layout.dispose()

  it 'should have el, $el and $ props / methods', ->
    expect(layout.el).to.be document.body
    expect(layout.$el).to.be.a $

  it 'should set the document title', () ->
    spy = sinon.spy()
    Backbone.on 'adjustTitle', spy
    Backbone.trigger 'adjustTitle', testController.title
    title = "#{testController.title} \u2013 #{layout.title}"
    expect(document.title).to.be title
    expect(spy).was.calledWith testController.title

  # Default routing options
  # -----------------------

  it 'should route clicks on internal links', ->
    expectWasRouted href: '/internal/link'

  it 'should correctly pass the query string', ->
    path = '/internal/link'
    query = 'foo=bar&baz=qux'

    stub = sinon.spy()
    Backbone.on 'router:route', stub
    linkAttributes = href: "#{path}?#{query}"
    createLink(linkAttributes).appendTo(document.body).click().remove()
    expect(stub).was.calledOnce()
    [passedPath] = stub.firstCall.args
    expect(passedPath).to.eql url: linkAttributes.href
    Backbone.off '!router:route', stub

  it 'should not route links without href attributes', ->
    expectWasNotRouted name: 'foo'

  it 'should not route links with empty href', ->
    expectWasNotRouted href: ''

  it 'should not route links to document fragments', ->
    expectWasNotRouted href: '#foo'

  it 'should not route links with a noscript class', ->
    expectWasNotRouted href: '/foo', class: 'noscript'

  it 'should not route rel=external links', ->
    expectWasNotRouted href: '/foo', rel: 'external'

  it 'should not route target=blank links', ->
    expectWasNotRouted href: '/foo', target: '_blank'

  it 'should not route non-http(s) links', ->
    expectWasNotRouted href: 'mailto:a@a.com'
    expectWasNotRouted href: 'javascript:1+1'
    expectWasNotRouted href: 'tel:1488'

  it 'should not route clicks on external links', ->
    old = window.open
    window.open = sinon.stub()
    expectWasNotRouted href: 'http://example.com/'
    expectWasNotRouted href: 'https://example.com/'
    expect(window.open).was.notCalled()
    window.open = old

  # With custom external checks
  # ---------------------------

  it 'custom isExternalLink receives link properties', ->
    stub = sinon.stub().returns true
    layout.isExternalLink = stub
    expectWasNotRouted href: 'http://www.example.org:1234/foo?bar=1#baz', target: "_blank", rel: "external"

    expect(stub).was.calledOnce()
    link = stub.lastCall.args[0]
    expect(link.target).to.be "_blank"
    expect(link.rel).to.be "external"
    expect(link.hash).to.be "#baz"
    expect(link.pathname.replace(/^\//, '')).to.be "foo"
    expect(link.host).to.be "www.example.org:1234"

  it 'custom isExternalLink should not route if true', ->
    layout.isExternalLink = -> true
    expectWasNotRouted href: '/foo'

  it 'custom isExternalLink should route if false', ->
    layout.isExternalLink = -> false
    expectWasRouted href: '/foo', rel: "external"

  # With custom routing options
  # ---------------------------

  it 'routeLinks=false should NOT route clicks on internal links', ->
    layout.dispose()
    layout = new Mildred.Layout title: '', routeLinks: false
    expectWasNotRouted href: '/internal/link'

  it 'openExternalToBlank=true should open external links in a new tab', ->
    old = window.open

    window.open = sinon.stub()
    layout.dispose()
    layout = new Mildred.Layout title: '', openExternalToBlank: true
    expectWasNotRouted href: 'http://www.example.org/'
    expect(window.open).was.called()

    window.open = sinon.stub()
    layout.dispose()
    layout = new Mildred.Layout title: '', openExternalToBlank: true
    expectWasNotRouted href: '/foo', rel: "external"
    expect(window.open).was.called()

    window.open = old

  it 'skipRouting=false should route links with a noscript class', ->
    layout.dispose()
    layout = new Mildred.Layout title: '', skipRouting: false
    expectWasRouted href: '/foo', class: 'noscript'

  it 'skipRouting=function should decide whether to route', ->
    path = '/foo'
    stub = sinon.stub().returns false
    layout.dispose()
    layout = new Mildred.Layout title: '', skipRouting: stub
    expectWasNotRouted href: path
    expect(stub).was.calledOnce()
    args = stub.lastCall.args
    expect(args[0]).to.be path
    expect(args[1]).to.be.an 'object'
    expect(args[1].nodeName).to.be 'A'

    stub = sinon.stub().returns true
    layout.dispose()
    layout = new Mildred.Layout title: '', skipRouting: stub
    expectWasRouted href: path
    expect(stub).was.calledOnce()
    expect(args[0]).to.be path
    expect(args[1]).to.be.an 'object'
    expect(args[1].nodeName).to.be 'A'


  it 'should dispose itself correctly', ->
    spy1 = sinon.spy()
    layout.on 'foo', spy1

    spy2 = sinon.spy()
    layout.delegateEvents 'click #testbed': spy2

    expect(layout.dispose).to.be.a 'function'
    layout.dispose()

    expect(layout.disposed).to.be true

    layout.trigger 'foo'
    $('#testbed').click()

    # It should unsubscribe from events
    expect(spy1).was.notCalled()
    expect(spy2).was.notCalled()

  it 'should be extendable', ->
    expect(Mildred.Layout.extend).to.be.a 'function'

    DerivedLayout = Mildred.Layout.extend()
    derivedLayout = new DerivedLayout()
    expect(derivedLayout).to.be.a Mildred.Layout

    derivedLayout.dispose()
