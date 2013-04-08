class Cartograph

  # Private

  param_regexp  = /:([\w\d]+)/g
  splat_regexp  = /\*\w+/g
  
  param_replace = "([^\/]+)"
  splat_replace = "(.*)"

  routeToRegExp = ( route ) ->
    escape_regexp = /[\-{}\[\]+?.,\\\^$|#\s]/g
    route =
      route
        .replace( escape_regexp, "\\$&" )
        .replace( param_regexp, param_replace )
        .replace( splat_regexp, splat_replace )
    new RegExp "^#{ route }$", "i"

  extractParamNames = ( route ) ->
    name_regexp = /[:|\*]([\w\d]+)/g
    names = name[1] while name = name_regexp.exec route

  parseQueryParams = ( querystr ) ->
    params = {}
    if querystr?
      re = /[\?&]([^=&]+)=?([^&$]+)?/g
      while match = re.exec querystr
        for k in [1..2]
          match[ k ] = decode match[ k ] if match[ k ]?
        if /\[\]$/.test match[1]
          name = match[1].replace /\[\]$/, ""
          params[ name ] ?= []
          params[ name ].push match[2]
        else
          params[ match[1] ] = match[2]
    params

  peek = ( array, idx = 1 ) ->
    array[ array.length - idx ]

  decode = ( v ) ->
    return v unless v?
    decodeURIComponent v.replace( "+", "%20" )

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
    prefixed_route = ( peek( @_prefix_stack ) or "" ) + route

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
    @_prefix_stack.push ( peek(@_prefix_stack) || "" ) + ns
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
