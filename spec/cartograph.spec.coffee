buster.spec.expose()

describe "Cartograph", ->

  before ->
    @c = new Cartograph

  describe "draw", ->

    it "executes the passed function in the scope of the newly created instance", ->
      probe = null
      @c.draw ->
        probe = @
      expect( probe ).toBe @c

  describe "map", ->

    it "throws an error if no route is provided", ->
      expect( => @c.map() ).toThrow()

    it "throws an error if callback is not a function", ->
      expect( => @c.map "foo", 123 ).toThrow()

    it "adds a new mapping", ->
      fn = ->
      @c.map "foo/bar", fn
      expect( @c.mappings.pop() ).toEqual
        route:    "foo/bar"
        callback: fn

  describe "match", ->

    before ->
      @fn1 = @spy()
      @fn2 = @spy()
      @fn3 = @spy()

    after ->
      delete @fn1
      delete @fn2
      delete @fn3

    it "executes only the callback of the first matching mapping", ->
      @c.mappings = [
        { route: "bar", callback: @fn1 },
        { route: "foo", callback: @fn2 },
        { route: "foo", callback: @fn3 }
      ]
      @stub @c, "scan", ( msg, route ) ->
        route is "foo"
      @c.match "foo"
      refute.called( @fn1 )
      expect( @fn2 ).toHaveBeenCalledOnce()
      refute.called( @fn3 )

    it "executes the callback passing the match object returned by scan()", ->
      @c.mappings = [
        { route: "foo", callback: @fn1 }
      ]
      @stub @c, "scan", ( msg, route ) ->
        return false unless route is "foo"
        match = 123
      @c.match "foo"
      expect( @fn1 ).toHaveBeenCalledWith( 123 )

    it "mixins the second argument's properties in the match objects", ->
      @c.mappings = [
        { route: "foo", callback: @fn1 }
      ]
      @stub @c, "scan", ( msg, route ) ->
        return false unless route is "foo"
        match =
          foo: "abc"
      @c.match "foo",
        bar: 123
        baz: 345
      expect( @fn1 ).toHaveBeenCalledWith
        foo: "abc"
        bar: 123
        baz: 345

    it "merges the params property in the match object with the one in the second argument", ->
      @c.mappings = [
        { route: "foo", callback: @fn1 }
      ]
      @stub @c, "scan", ( msg, route ) ->
        return false unless route is "foo"
        match =
          params:
            bar: 123
      @c.match "foo",
        params:
          baz: 345
      expect( @fn1 ).toHaveBeenCalledWith
        params:
          bar: 123
          baz: 345

  describe "matchLocation", ->

    before ->
      @loc =
        pathname: "foo/bar"

    after ->
      delete @loc

    it "calls match() passing location.pathname and mixing in the location properties", ->
      @stub( @c, "match" )
      @c.matchLocation @loc
      expect( @c.match ).toHaveBeenCalledOnceWith( @loc.pathname, @loc )

    it "parses query params and mixes them into params", ->
      @stub( @c, "match" )
      @loc.search = "?foo=bar&baz=123&qux"
      @c.matchLocation @loc
      mixin =
        params:
          foo: "bar"
          baz: "123"
          qux: undefined
      mixin[ k ] = v for k, v of @loc
      expect( @c.match ).toHaveBeenCalledOnceWith( @loc.pathname, mixin )

  describe "scan", ->
    
    it "returns false if there is no match", ->
      match = @c.scan "foo", "bar"
      expect( match ).toBeFalse()

    it "extracts named parameters", ->
      match = @c.scan "foo/qux/baz", "foo/:bar/baz"
      expect( match.params.bar ).toEqual "qux"

    it "extracts splats", ->
      match = @c.scan "foo/qux/quux/baz", "foo/*bar/baz"
      expect( match.params.bar ).toEqual "qux/quux"

    describe "when a mapping is provided as the third argument", ->

      it "caches the regexp in the mapping", ->
        mapping = {}
        @c.scan "foo/bar/baz", "foo/:bar/baz", mapping
        expect( mapping.regexp ).toBeDefined()

      it "uses the existing regexp in the mapping if available", ->
        mapping =
          regexp: /foo/
        match = @c.scan "foo/bar/baz", "xxx", mapping
        expect( match ).toBeObject()

  describe "namespace", ->

    it "proxies calls to map() to Cartograph#map after namespacing them", ->
      cbk = ->
      @stub @c, "map"
      @c.namespace "foo", ->
        @map "/bar", cbk
      expect( @c.map ).toHaveBeenCalledOnceWith "foo/bar", cbk
