# Mildred - Application Architecture for Backbone.js

**Mildred** is a backbone.js application architecture forked from [ChaplinJS](http://chaplinjs.org/). the main goal of Mildred is to be a simpler to use Chaplin.js, with no AMD required and some fancy features left out.

[![Build Status](https://travis-ci.org/snird/Mildred.png)](https://travis-ci.org/snird/Mildred)

## Changes from ChaplinJS
### non-amd
Mildred most important feature is that it's written as non-amd ready library, it lives in the namespace under Mildred.XXX.

### Controllers And Dispatcher
Since Mildred is non-amd fork, The dispatcher logic and the Controllers workflow changed a lot.
In ChaplinJS the Dispatcher loads the controller using the AMD module provided, so the controllers are restricted to be at a specific directory with specific names.
Mildred handle this differently, your Controllers may live wherever you want them to be as long as you give them to Mildred as an Array or an Object.

In the Application intialization you should give the app an option called 'controllers' with your controllers, either as an object or as an array.
e.g:
'''lang=coffeescript
class MyApp extends Mildred.Application
  title: "example"

# The initialization
new MyApp
  routes: routes_var
  controllers: [MainController, AnotherController, name_controller, also_Controller, justname]
'''

as you can see, Mildred accepts all sort of naming conventions: "nameController", "name_controller", "name_Controller" etc' or just a name without "controller" in it.
that's it so you can use the name on your routes without the ending "controller", as you can in Chaplin.

The object paradigm is useful when you would like to keep your app logic under some namespace and all your controllers are under some Object already.
e.g:
'''lang=coffeescript
class MyApp.Controllers.Main extends Mildred.Controller
  # logic here

class MyApp.Controllers.AnotherController extends Mildred.Controller
  # logic here

# The initialization
new MyApp
  routes: routes_var
  controllers: MyApp.Controllers
'''


some more differences to be well documented:

*   Access to components is made by Mildred.Component, e.g: Mildred.Model, Mildred.Controller, Mildred.Layout etc'
*   Mediator and event_broker are completely gone. use Backbone.js events instead, they are great and in my opinion the Mediator wrapper for them was redundant and causing confusion.
*   No regions at all.
*   Views - the noWrap functionality is gone.
*   Templating - by default we assume using the underscore built in template render. you may give the application an application wide templating function, in the options to the Application object under the name "templateFunction", and as always, you can override it in the view by overriding the getTemplateFunction as it is in Chaplin.

This sums it up for now, I hope to get a full documentation soon, but if you come from Chaplin experience you can get it work, or you can just follow Chaplin's documentation with this changes in mind.

## Build, Test, Contribute

1. `sudo npm install -g grunt-cli`
2. `cd mildred && npm install && npm build`
3. `npm test` or `open test/index.html`
4. `grunt watch`