describe 'Controller', ->
  controller = null

  beforeEach ->
    controller = new Mildred.Controller()

  afterEach ->
    controller.dispose()
    Backbone.off 'router:route'

  it 'should mixin a Backbone.Events', ->
    for own name, value of Backbone.Events
      expect(controller[name]).to.be Backbone.Events[name]

  it 'should be extendable', ->
    expect(Mildred.Controller.extend).to.be.a 'function'

    DerivedController = Mildred.Controller.extend()
    derivedController = new DerivedController()
    expect(derivedController).to.be.a Mildred.Controller

    derivedController.dispose()

  it 'should redirect to a URL', ->
    expect(controller.redirectTo).to.be.a 'function'

    routerRoute = sinon.spy()
    Backbone.on 'router:route', routerRoute

    url = 'redirect-target/123'
    controller.redirectTo url

    expect(controller.redirected).to.be true
    expect(routerRoute).was.calledWith url

  it 'should redirect to a URL with routing options', ->
    routerRoute = sinon.spy()
    Backbone.on 'router:route', routerRoute

    url = 'redirect-target/123'
    options = replace: true
    controller.redirectTo url, options

    expect(controller.redirected).to.be true
    expect(routerRoute).was.calledWith url, options

  it 'should redirect to a named route', ->
    routerRoute = sinon.spy()
    Backbone.on 'router:route', routerRoute

    name = 'params'
    params = one: '21'
    pathDesc = name: name, params: params
    controller.redirectTo pathDesc

    expect(controller.redirected).to.be true
    expect(routerRoute).was.calledWith pathDesc

  it 'should redirect to a named route with options', ->
    routerRoute = sinon.spy()
    Backbone.on 'router:route', routerRoute

    name = 'params'
    params = one: '21'
    pathDesc = name: name, params: params
    options = replace: true
    controller.redirectTo pathDesc, options

    expect(controller.redirected).to.be true
    expect(routerRoute).was.calledWith pathDesc, options

  it 'should adjust page title', ->
    spy = sinon.spy()
    Backbone.on 'adjustTitle', spy
    controller.adjustTitle 'meh'
    expect(spy).was.calledOnce()
    expect(spy).was.calledWith 'meh'

  describe 'Disposal', ->
    it 'should dispose itself correctly', ->
      expect(controller.dispose).to.be.a 'function'
      controller.dispose()

      expect(controller.disposed).to.be true

    it 'should dispose disposable properties', ->
      model = controller.model = new Mildred.Model()
      view = controller.view = new Mildred.View model: model

      controller.dispose()

      expect(controller).not.to.have.own.property 'model'
      expect(controller).not.to.have.own.property 'view'

      expect(model.disposed).to.be true
      expect(view.disposed).to.be true

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = sinon.spy()
      controller.on 'foo', pubSubSpy

      controller.dispose()

      controller.trigger 'foo'
      expect(pubSubSpy).was.notCalled()

    it 'should unsubscribe from other events', ->
      spy = sinon.spy()
      model = new Mildred.Model
      controller.listenTo model, 'foo', spy

      controller.dispose()

      model.trigger 'foo'
      expect(spy).was.notCalled()
