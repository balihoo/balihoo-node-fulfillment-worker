Stream = require 'stream'
Promise = require 'bluebird'

epoch = -> (new Date).getTime()

###
  Utility stream writer that sends a heartbeat every once
  in a while to report activity progress.
###
module.exports = class ActivityProgressListener extends Stream.Writable

  ###
    @param {object} streamOpts Options to be passed to parent Stream class.
    @param {object} interval Number of seconds between before sending a heartbeat.
    @param {function} heartbeatAsync Function that can be invoked to send heartbeat asynchronously.
  ###
  constructor: (@interval, @heartbeatFunc, streamOpts = {}) ->
    super streamOpts
    @processed = 0
    @last = epoch()

  ###
    Emits a heartbeat record request and update last timestamp.
  ###
  notify: ->
    @last = epoch()
    @heartbeatFunc "Progress: #{@processed} elements processed"

  ###
    Handles a data event, whether invoked through _write or on 'data' event.
    @returns {boolean} true if a heartbeat has been recorded, otherwise false.
  ###
  handler: =>
    @processed++
    if epoch() - @last > @interval * 1000
      @notify().then -> true
    else
      Promise.resolve false

  _write: (chunk, enc, cb) ->
    @handler()
      .then -> cb null, chunk
      .catch (err) => @emit 'error', err
