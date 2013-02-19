# Cartograph

Minimal JavaScript router

## Usage

```javascript
var Router = new Cartograph(function() {

  this.map("/foo/:id", function( res ) {
    console.log( "id is: " + res.params["id"] );
  });

  this.namespace("/users", function() {

    var users = UsersController;

    this.map( "/", users.index );

    this.map( "/:id", users.show );

    this.map( "/new", users.new );

  });

});

// Match current location (will execute the first matching route)
Router.matchLocation( window.location );
```
