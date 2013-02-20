class Cartograph

  # Private

  param_regexp  = /:([\w\d]+)/g
  splat_regexp  = /\*/g

  routeToParamRegExp = ( route ) ->
    param_replace = "([^\/]+)"
    splat_replace = ".*"
    routeToRegexp route, param_replace, splat_replace

  routeToSplatRegExp = ( route ) ->
    param_replace = "[^\/]+"
    splat_replace = "(.*)"
    routeToRegexp route, param_replace, splat_replace

  routeToRegexp = ( route, param_replace, splat_replace ) ->
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
      params[ match[1] ] = match[2] while match = re.exec querystr
    params

  # Public

  constructor: ( fn ) ->
    @draw fn if typeof fn is "function"

  draw: ( fn ) ->
    fn.call @

  map: ( route, fn ) ->
    @mappings ?= []

    unless typeof route is "string"
      return throw new Error("route must be a string")
    unless typeof fn is "function"
      return throw new Error("callback must be a function")

    @_prefix ?= ""

    @mappings.push
      route: @_prefix + route
      callback: fn

  match: ( path, mixin ) ->
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
        mapping.callback match
        break

  matchRequest: ( req = window.location ) ->
    mixin = {}
    mixin.params = parseQueryParams req.search if req.search?
    mixin[ key ] = val for key, val of req
    @match req.pathname, mixin

  scan: ( path, route, mapping = {} ) ->
    param_re = mapping.param_regexp || routeToParamRegExp route
    mapping.param_regexp = param_re
    return false unless param_re.test path
    splat_re = mapping.splat_regexp || routeToSplatRegExp route
    mapping.splat_regexp = splat_re
    param_data = param_re.exec path
    splat_data = splat_re.exec path
    param_names = mapping.param_names || extractParamNames route
    mapping.param_names = param_names
    params = {}
    params[ name ] = param_data[ i + 1 ] for name, i in param_names
    params.splats = splat_data[1..]
    match =
      params: params

  namespace: ( ns, fn ) ->
    tmp = @_prefix || ""
    @_prefix += ns
    fn.call @
    @_prefix = tmp

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
