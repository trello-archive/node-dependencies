_     = require 'underscore'
async = require 'async'
fs    = require 'fs'
npm   = require 'npm'
path  = require 'path'

optimist = require('optimist')
            .describe('sort', 'Order to print (alpha, urgency)')
            .describe('homepage', 'Print the homepage url with each library')
            .describe('pre', 'Check packages with non-numeric patch values')
            .alias('h', 'help')

opts = optimist.argv

if opts.help
  optimist.showHelp()
  process.exit(0)

### Stuff
# local revisions
# relative timestamps
#
###

class Dependencies
  status: (next) ->
    async.waterfall [
      @package_names
      @package_details
    ], next

  package_names: (next) ->
    # Load node_modules directory
    async.waterfall [
      (next) ->
        fs.readdir('node_modules', next)

      (files, next) ->
        async.filter files, (filename, next) ->
          fs.exists "node_modules/#{ filename }/package.json", next
        , (res) -> next(null, res)
    ], next

  package_details: (packages, next) ->
    # Print header
    PackageStatus.header()
    # Iterate over packages, collect data, and send to output
    debugger
    async.waterfall [
      (next) ->
        async.map packages, (name, next) ->
          new Package(name).status (err, status) ->
            if err
              PackageStatus.error(name, err)
              return next()
            
            if opts.sort
              next(null, status)
            else
              status?.print()
              next(null, null)
        , next

      (statuses, next) ->
        _.chain(statuses)
          .compact()
          .sortBy (s) ->
            if opts.sort == 'alpha'
              s.name
            else
              _.values(PackageStatus.FLAG).indexOf(s.status_color(s.diff(s.local, s.remote)))
          .each (s) ->
            s?.print()
        next()
    ], next

class Package
  constructor: (@name) ->

  status: (next) ->
    # Entry point
    @fetch_information (err, {local, remote}={}) =>
      next err, new PackageStatus(this, local, remote)

  fetch_information: (next) ->
    async.auto
      local:  @fetch_local
      remote: @fetch_remote
    , next

  local_manifest: ->
    try
      require path.resolve(process.cwd(), "./node_modules/#{ @name }/package.json")
    catch err
      throw Error("No manifest for #{ @name }")

  fetch_local: (next) =>
    manifest = @local_manifest()
    unless manifest.version
      return next(Error("No local manifest found for #{ @name }."))
    next(null, manifest.version)

  fetch_remote: (next) =>
    async.waterfall [
      # Inject proper name into fetch
      (next) => next(null, @local_manifest().name)
      @fetch_manifest
      @parse_manifest
    ], next

  fetch_manifest: (name, next) =>
    npm.load loglevel: 'silent', =>
      npm.commands.view [name], true, next

  parse_manifest: (manifest, next) =>
    latest = _.first(_.values(manifest))
    @homepage = latest?.repository?.web ? latest?.repository?.url
    version = {}
    for [number, date] in _.pairs(latest.time)
      @add_version(version, number, new Date(date))
    next(null, version)

  add_version: (store, number, value) ->
    [first, rest...] = number.split('.')
    return value unless first
    return store if not opts.pre and /\D/.test(first)
    store[first] = @add_version store[first] ? {}, rest.join('.'), value
    return store

class PackageStatus
  @FLAG:
    PATCH: 1 # Red
    MINOR: 3 # Yellow
    MAJOR: 7 # White
    OK: 2 # Green

  @column_data: [
    ['Package',      'rpad', 20]
    ['Local',        'lpad', 10]
    ['Major', 'lpad', 10]
    ['Minor', 'lpad', 10]
    ['Patch', 'lpad', 10]
  ]

  constructor: (@package, local, @remote) ->
    @local = @parse_version(local) if local

  @header: ->
    console.log new PackageStatus().row_format()

  @error: (name, err) ->
    # Print standard error message for given package
    # console.log(name, err.toString())

  print: ->
    status = @diff @local, @remote
    column_contents = [@package.name, _.values(@local).join('.')].concat(@status_format(status))

    console.log @colorize(@status_color(status))(@row_format column_contents)

    if opts.homepage and @package.homepage
      console.log @colorize(5)("  #{@package.homepage.replace(///^git://github.com///, 'https://github.com')}")

  diff: (version, available) ->
    # Returns an object with {major, minor, patch}. Each value is the newest
    # available version for the given version on that subversion. So, {minor} is
    # the newest minor assuming major is version.major. The values given are
    # {version, date}
    status =
      major: @latest(available)
      minor: @latest(available, [version.major])
      patch: @latest(available, [version.major, version.minor])

  latest: (list, prefix=[]) ->
    version_bits = _.clone(prefix)
    while (subver = prefix.shift())
      list = list?[subver]
    return null unless list
    latest = @latest_from(list)

    {
      version: version_bits.concat(latest).join('.')
      bit: _.first(latest)
    }

  latest_from: (list) ->
    return [] unless _.size(list) > 0
    [subversion, rest] = _.last(_.pairs(list))
    [subversion].concat(@latest_from(rest))

  status_color: (status) ->
    # If we don't have a value for each one, shit is messed up (i.e., the
    # package we're using isn't on npm for some reason)
    if _.compact(_.values(status)).length < 3
      # Give them the red severity
      PackageStatus.FLAG.PATCH
    # Determines the status color as follows:
    # - if there is a newer patch for your major.minor => red
    # - if there is a newer minor for your major => yellow
    # - if there is a new major => white
    # - else => green
    else if @local.patch != status.patch.bit
      PackageStatus.FLAG.PATCH
    else if @local.minor != status.minor.bit
      PackageStatus.FLAG.MINOR
    else if @local.major != status.major.bit
      PackageStatus.FLAG.MAJOR
    else
      PackageStatus.FLAG.OK

  parse_version: (version) ->
    _.object(_.zip(['major', 'minor', 'patch'], version.split('.')))

  colorize: (color) ->
    # Returns a function that takes a string and wraps it in the given color
    (str) -> "\x1b[3#{ color }m#{ str }\x1b[0m"

  row_format: (cols=[]) ->
    PackageStatus.column_data.map ([header, fn, args...], i) =>
      @[fn](cols[i] ? header, args...)
    .join(' ')

  lpad: (str, n) ->
    # Left pad a string by n spaces
    new Array(n+1).join(' ').concat(str).slice(-n)

  rpad: (str, n) ->
    # Right pad a string by n spaces
    str.concat(new Array(n+1).join(' ')).slice(0, n)

  status_format: (status) ->
    for key, value of @local
      if not status[key]?
        'UNKNOWN'
      else if status[key].bit == value
        '---'
      else
        status[key].version

# Main
new Dependencies().status (err, res) ->
  #console.log("Error:", err) if err
  #console.log("Result:", res) if res
