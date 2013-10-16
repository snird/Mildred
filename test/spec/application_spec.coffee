describe 'Application', ->
  app = null

  getApp = (noInit) ->
    if noInit
      return class extends Mildred.Application
        initialize: ->
          return
    else
      return Mildred.Application

  beforeEach ->
    app = new (getApp true)

  afterEach ->
    app.dispose()

  it 'should be a simple object', ->
    expect(app).to.be.an 'object'
    expect(app).to.be.a Mildred.Application

  it 'should have initialize function', ->
    expect(app.initialize).to.be.a 'function'
    app.initialize()

  it 'should create a dispatcher', ->
    expect(app.initDispatcher).to.be.a 'function'
    app.initDispatcher()
    expect(app.dispatcher).to.be.a Mildred.Dispatcher

  it 'should create a layout', ->
    expect(app.initLayout).to.be.a 'function'
    app.initLayout()
    expect(app.layout).to.be.a Mildred.Layout

  it 'should create a composer', ->
    expect(app.initComposer).to.be.a 'function'
    app.initComposer()
    expect(app.composer).to.be.a Mildred.Composer

  it 'should create a router', ->
    passedMatch = null
    routesCalled = false
    routes = (match) ->
      routesCalled = true
      passedMatch = match

    expect(app.initRouter).to.be.a 'function'
    expect(app.initRouter.length).to.be 2
    app.initRouter routes, root: '/', pushState: false

    expect(app.router).to.be.a Mildred.Router
    expect(routesCalled).to.be true
    expect(passedMatch).to.be.a 'function'

  it 'should start Backbone.history with start()', ->
    app.initRouter (->), root: '/', pushState: false
    app.start()
    expect(Backbone.History.started).to.be true
    Backbone.history.stop()

  it 'should throw an error on double-init', ->
    expect(-> (new (getApp false)).initialize()).to.throwError()

  it 'should dispose itself correctly', ->
    expect(app.dispose).to.be.a 'function'
    app.dispose()

    for prop in ['dispatcher', 'layout', 'router', 'composer']
      expect(app[prop]).to.be null

    expect(app.disposed).to.be true

  it 'should be extendable', ->
    app.dispose()
    Backbone.history.stop()
    expect(Mildred.Application.extend).to.be.a 'function'

    DerivedApplication = Mildred.Application.extend()
    derivedApp = new DerivedApplication()
    expect(derivedApp).to.be.a Mildred.Application

    derivedApp.dispose()
