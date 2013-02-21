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

  describe "matchRequest", ->

    before ->
      @req =
        pathname: "foo/bar"

    after ->
      delete @req

    it "calls match() passing location.pathname and mixing in the location properties", ->
      @stub( @c, "match" )
      @c.matchRequest @req
      expect( @c.match ).toHaveBeenCalledOnceWith( @req.pathname, @req )

    it "parses query params and mixes them into params", ->
      @stub( @c, "match" )
      @req.search = "?foo=bar&baz=123&qux"
      @c.matchRequest @req
      mixin =
        params:
          foo: "bar"
          baz: "123"
          qux: undefined
      mixin[ k ] = v for k, v of @req
      expect( @c.match ).toHaveBeenCalledOnceWith( @req.pathname, mixin )

  describe "scan", ->
    
    it "returns false if there is no match", ->
      match = @c.scan "foo", "bar"
      expect( match ).toBeFalse()

    it "extracts named parameters", ->
      match = @c.scan "foo/qux/baz", "foo/:bar/baz"
      expect( match.params.bar ).toEqual "qux"

    it "extracts splats", ->
      match = @c.scan "foo/quux/quuux/baz/123/", "foo/*/baz/*"
      expect( match.params.splats ).toEqual ["quux/quuux", "123/"]

    it "works properly when path contains characters with special meaning in regexps", ->
      match = @c.scan "/123/foo-bar.json", "/:id/foo-*.*"
      expect( match.params ).toMatch
        splats: ["bar", "json"]
        id: "123"

    describe "when a mapping is provided as the third argument", ->

      it "caches regexps and param names in the mapping", ->
        mapping = {}
        @c.scan "foo/bar/baz", "foo/:bar/baz", mapping
        expect( mapping.param_regexp ).toBeDefined()
        expect( mapping.splat_regexp ).toBeDefined()
        expect( mapping.param_names ).toBeDefined()

      it "uses the existing regexps and param names in the mapping if available", ->
        mapping =
          param_regexp: /(foo)/
          splat_regexp: /(bar)/
          param_names:  ["foo"]
        match = @c.scan "foo/bar/baz", "xxx", mapping
        expect( match.params ).toMatch
          splats: ["bar"]
          foo: "foo"

  describe "namespace", ->

    it "namespaces routes", ->
      cbk = ->
      @c.namespace "/foo", ->
        @map "/bar", cbk
      expect( @c.mappings.pop().route ).toEqual "/foo/bar"

    it "closes namespace afterward", ->
      cbk = ->
      @c.namespace "/foo", ->
      @c.map "/baz", cbk
      expect( @c.mappings.pop().route ).toEqual "/baz"

    it "can be nested multiple times", ->
      cbk = ->
      @c.namespace "/foo", ->
        @namespace "/bar", ->
          @map "/baz", cbk
      expect( @c.mappings.pop().route ).toEqual "/foo/bar/baz"
