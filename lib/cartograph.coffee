class Cartograph

  # Private

  routeToRegExp = ( route ) ->
    named_param_regexp  = /:([\w\d]+)/g
    named_param_replace = "([^\/]+)"

    splat_regexp  = /\*([\w\d]+)/g
    splat_replace = "(.*)"

    route =
      route
        .replace( named_param_regexp, named_param_replace )
        .replace( splat_regexp, splat_replace )
    new RegExp "^#{ route }$", "gi"

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

    @mappings.push
      route:  route
      callback: fn

  match: ( msg, mixin ) ->
    for mapping in @mappings
      if match = @scan msg, mapping.route
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

  matchLocation: ( loc = window.location ) ->
    mixin = {}
    mixin.params = parseQueryParams loc.search if loc.search?
    mixin[ key ] = val for key, val of loc
    @match loc.pathname, mixin

  scan: ( msg, route ) ->
    re   = routeToRegExp route
    data = re.exec msg
    return false unless data?
    names = extractParamNames route
    params = {}
    data.shift()
    params[ name ] = data[ i ] for name, i in names
    match =
      params: params

  namespace: ( ns, fn ) ->
    self = @
    proxy =
      map: ( route, cbk ) ->
        self.map ns + route, cbk
    fn.call proxy

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
