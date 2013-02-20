# Cartograph

Minimal JavaScript routing microframework connecting paths to functions.


## Why?

Web apps frequently need to initialize client-side JavaScript on a per-page
basis. Initializing stuff with inline JavaScript works for small applications,
but when they grow larger it does not scale: there is no single place
responsible for setting up the state. `Cartograph` comes to the rescue,
providing a simple and barebone routing logic matching URL paths to JavaScript
functions, so you can run code depending on the current URL. It has a clean and
readable DSL with support for named URL parameters and splats. All in a
microscopic framework of less than 2Kb of code.


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
Router.matchLocation();
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
Router.matchLocation()
```


## Methods

### new Cartograph( [fn] )

When called with a function `fn`, the constructor executes it in the scope of
the newly created instance, providing a closure for route definitions.

### map( route, fn )

Adds a mapping for `route` to function `fn`. Whenever `match` or
`matchLocation` is called and this route is the first one matching, `fn` is
executed passing an object containing information on the request and the named
params. `route` is a string path, and can contain named params (e.g.
`"/foo/:id"`) and named splats (e.g. `"/foo/*splat/bar"`).

### namespace( ns, fn )

Provides a namespace block. Whithin function `fn`, all routes defined by
calling `map` are prefixed with the namespace `ns`.

### match( path, [mixin] )

Gets a `path` string and match it against each mapping in order until a match
is found. If a matching route is found, it executes its callback function
passing an object containing information about the request and the params. If a
`mixin` object is provided, its properties are mixed in the request object (so
that additional request info or params can be inserted).

### matchLocation( [location] )

Similar to `match`, but it is meant to take an object similar to
`window.location` (exposing a `pathname` property) as argument
instead of a path string. If no argument is provided,
`window.location` is taken (this is the only case in which
`Cartograph` makes a soft assumption of being in the browser). It
also mixes into the request object the parsed query string params, as
well as all properties of `location`, so that they become available
to the callback. This method should usually be called upon page load
and at every `pushState` call or `popstate` event.

### draw( fn )

Like the constructor, it executes function `fn` in the scope of the
`Cartograph` instance. It is useful for adding routes, especially if the route
definition is splitted in multiple files.
