# Mildred - Application Architecture for Backbone.js

**Mildred** is a backbone.js application architecture forked from [ChaplinJS](http://chaplinjs.org/). the main goal of Mildred is to be a simpler to use Chaplin.js, with no AMD required and some fancy features left out.

[![Build Status](https://travis-ci.org/snird/Mildred.png)](https://travis-ci.org/snird/Mildred)

For those who come from Chaplin.js background and experience here are the major differences:

*   No AMD required - the mildred.js file is standalone and full.
*   Access to components is made by Mildred.Component, e.g: Mildred.Model, Mildred.Controller, Mildred.Layout etc'
*   Mediator and event_broker are completely gone. use Backbone.js events instead, they are great and in my opinion the Mediator wrapper for them was redundant and causing confusion.
*   Controllers - since no there is no AMD, and since reading the controllers by folder structure seems a bit restrictive to me, you should pass your controllers as an array to the Mildred.Application object as one of the options, called controllers.
*   Controllers and Router - to make it easier to you, we parse the controller name automatically with "Controller" or "_Controller" sliced out, meaning: you have a controller name "IndexController", you should refer to the "show" method of this controller for example in the router as "Index#show". same goes for "ControllerIndex", "Index_Controller", "index_controller" and so on.
*   No regions at all.
*   Views - the noWrap functionality is gone.
*   Templating - by default we assume using the underscore built in template render. you may give the application an application wide templating function, in the options to the Application object under the name "templateFunction", and as always, you can override it in the view by overriding the getTemplateFunction as it is in Chaplin.

This sums it up for now, I hope to get a full documentation soon, but if you come from Chaplin experience you can get it work, or you can just follow Chaplin's documentation with this changes in mind.

## Build, Test, Contribute

1. `sudo npm install -g grunt-cli`
2. `cd mildred && npm install && npm build`
3. `npm test` or `open test/index.html`
4. `grunt watch`