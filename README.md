# Cartograph

Minimal JavaScript routing microframework connecting paths to functions.


## Why?

Web apps frequently need to initialize client-side JavaScript on a per-page
basis. Initializing stuff with inline JavaScript works for small
applications, but when they grow larger it does not scale: there is no single
place responsible for setting up the state. `Cartograph` comes to the rescue,
providing a simple and barebone routing logic matching URL paths to
JavaScript functions, so you can run code depending on the current URL. It
has a clean and readable DSL with support for named URL parameters and
splats. All in a microscopic framework of ~2Kb of minified code.


## Example Usage

```javascript
var Router = new Cartograph(function() {

  // Connect route to a function:
  this.map("/foo/:id", function( req ) {
    // `req` is an object containing the params
    // and other information on the request
    console.log( "Requested id is: " + req.params["id"] );
  });

  // Namespaced routes:
  this.namespace("/users", function() {

    // Say we have a controller object:
    var users = UsersController;

    this.map( "/", users.index );

    this.map( "/:id", users.show );

    this.map( "/new", users.new );

  });

});

// Unleash the magic! (will get window.location
// and execute the first matching route)
Router.routeRequest();
```

And with CoffeeScript it's even more fun:

```coffeescript
Router = new Cartograph ->

  @map "/foo/:id", ( req ) ->
    console.log "Requested id is #{req.params['id']}"

  @namespace "/users", ->

    users = UsersController

    @map "/", users.index

    @map "/:id", users.show

    @map "/new", users.new

# Unleash the magic!
Router.routeRequest()
```


## Methods

### new Cartograph( [fn] )

When called with a function `fn`, the constructor executes it in the scope of
the newly created instance, providing a closure for route definitions.

### map( route, fn )

Adds a mapping for `route` to function `fn`. Whenever `route` or
`routeRequest` is called, mappings are checked in order until the first
matching route is found. The callback function for that route is then
executed, passing as the first argument a request object.

Routes are strings, and can contain named params (e.g.  `"/foo/:id"`) and
named splats (e.g. `"/foo/*bar/baz"`). The request object passed to `fn`
exposes a `params` key/value object property containing params and splats.

### namespace( ns, fn )

Provides a namespace block. Whithin function `fn`, all routes defined by
calling `map` are prefixed with the namespace `ns`.

### route( path, [mixin] )

Gets a `path` string and match it against each route in order until a match
is found. If a matching route is found, it executes its callback function
passing an object containing information about the request and the params. If
a `mixin` object is provided, its properties are mixed in the request object
(so that additional request info or params can be inserted).

### routeRequest( [request] )

Similar to `route`, but it takes as argument a request object exposing at
least a `pathname` property. If no argument is provided, `window.location` is
taken (this is the only case in which `Cartograph` makes a soft assumption of
being in the browser).

When building the object to be passed to the matched callback, it also mixes in
it all the request properties and all the params parsed from the querystring
(looked for in `request.search`), so that they become available to the
callback. Querystring params ending with `[]` are parsed into an array (e.g.
`/mypath?foo[]=abc&foo[]=def&bar=ghi` will be parsed to params `{ foo: ["abc",
"def"], bar: "ghi" }`).

### draw( fn )

Like the constructor, it executes function `fn` in the scope of the
`Cartograph` instance. It is useful for adding routes, especially if the
route definition is splitted in multiple files.


## Contributing

Contributes are very welcome! If you have an idea about how to make
`Cartograph` better, you should:

  1. Fork the project and setup the environment with `npm install`

  2. Write your new features/fixes and relative tests in CoffeeScript. The
     test suite uses [BusterJS](http://busterjs.org), and can be run with
     `npm test` after starting the Buster server.

  3. Send a pull request (please do not change the version in `package.json`)
