class Cartograph

  # Private

  param_regexp  = /:([\w\d]+)/g
  splat_regexp  = /\*\w+/g
  
  param_replace = "([^\/]+)"
  splat_replace = "(.*)"

  # turn the given route string to the corresponding regular expression
  routeToRegExp = ( route ) ->
    escape_regexp = /[\-{}\[\]+?.,\\\^$|#\s]/g
    route =
      route
        .replace( escape_regexp, "\\$&" )
        .replace( param_regexp, param_replace )
        .replace( splat_regexp, splat_replace )
    new RegExp "^#{ route }$", "i"

  # extract all param names from the given route
  extractParamNames = ( route ) ->
    name_regexp = /[:|\*]([\w\d]+)/g
    names = name[1] while name = name_regexp.exec route

  # set a (possibly) nested param.
  # E.g. `setNestedParam( params, "foo[bar][baz]", "xxx" )` would set
  # `params.foo.bar.baz` to `"xxx"`.
  setNestedParam = ( obj, nesting, value, overwrite = true ) ->
    part_regexp = /\[([^\]]+)\]/g
    root_regexp = /^([^\[]+)(\[|$)/
    root        = root_regexp.exec( nesting )?[1]
    parts       = [ root ]
    while part = part_regexp.exec nesting
      parts.push part[1]
    last_part = parts.pop()
    for part in parts
      obj[ part ] ?= {}
      obj = obj[ part ]
    obj[ last_part ] = value if overwrite or !obj[ last_part ]?
    obj[ last_part ]

  # takes a query string and returns the params parsed as an object
  parseQueryParams = ( querystr ) ->
    params = {}
    if querystr?
      re = /[\?&]([^=&]+)=?([^&$]+)?/g
      while match = re.exec querystr
        for k in [1..2]
          match[ k ] = decode match[ k ] if match[ k ]?
        if /\[\]$/.test match[1]
          name  = match[1].replace /\[\]$/, ""
          param = setNestedParam( params, name, [], false )
          param.push match[2]
        else
          setNestedParam( params, match[1], match[2] )
    params

  # return last element of an array
  lastElemOf = ( array ) ->
    array[ array.length - 1 ]

  # proper URI component decoding, playing nice with '+'
  decode = ( v ) ->
    return v unless v?
    decodeURIComponent v.replace( /\+/g, "%20" )

  # Public

  constructor: ( fn ) ->
    @draw fn if typeof fn is "function"

  draw: ( fn ) ->
    fn.call @

  map: ( route, fn ) ->
    @mappings ?= []

    unless typeof route is "string"
      throw new Error("route must be a string")
    unless typeof fn is "function"
      throw new Error("callback must be a function")

    @_prefix_stack ?= []
    prefixed_route = ( lastElemOf( @_prefix_stack ) or "" ) + route

    @mappings.push
      route: prefixed_route
      callback: fn

  route: ( path, mixin ) ->
    for mapping in @mappings
      if match = @scan path, mapping.route
        if mixin?
          params = mixin.params
          delete mixin.params
          match[ key ] = val for key, val of mixin
          if params? and not match.params?
            match.params = params
          else
            match.params[ key ] = val for key, val of params
        return mapping.callback match
    return null

  routeRequest: ( req = window.location ) ->
    mixin = {}
    mixin.params = parseQueryParams req.search if req.search?
    mixin[ key ] = val for key, val of req
    @route req.pathname, mixin

  scan: ( path, route, mapping = {} ) ->
    mapping.regexp = mapping.regexp or routeToRegExp route
    return false unless mapping.regexp.test path
    data = mapping.regexp.exec path
    mapping.param_names = mapping.param_names or extractParamNames route
    params = {}
    for name, i in mapping.param_names
      params[ name ] = decode data[ i + 1 ]
    match =
      params: params

  namespace: ( ns, fn ) ->
    @_prefix_stack ?= []
    @_prefix_stack.push ( lastElemOf(@_prefix_stack) || "" ) + ns
    fn.call @
    @_prefix_stack.pop()

# Export as:
# CommonJS module
if exports?
  if module? and module.exports?
    exports = module.exports = Cartograph
  exports.Cartograph = Cartograph
# AMD module
else if typeof define is "function" and define.amd
  define ->
    Cartograph
# Browser global
else
  @Cartograph = Cartograph
