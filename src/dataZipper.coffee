zlib = require 'zlib'
Promise = require 'bluebird'
Promise.promisifyAll zlib

exports.INLINE_ZIP_THRESHOLD = INLINE_ZIP_THRESHOLD = 32768
exports.ZIP_PREFIX = ZIP_PREFIX = 'FF-ZIP'
exports.SEPARATOR = SEPARATOR = ':'

exports.deliver = (workResult) ->
  Promise.try ->
    stringResult = JSON.stringify workResult
    byteCount = Buffer.byteLength stringResult, 'utf8'

    if byteCount < INLINE_ZIP_THRESHOLD
      return workResult
      
    zlib.deflateAsync stringResult
    .then (compressed) ->
      encoded = new Buffer compressed
      .toString 'base64'

      return "#{ZIP_PREFIX}:#{byteCount}:#{encoded}"

exports.receive = (input) ->
  Promise.try ->
    if typeof input isnt 'string' or input.slice(0, ZIP_PREFIX.length) isnt ZIP_PREFIX
      return input
    
    parts = input.split SEPARATOR
    throw new Error "Malformed zip data"  if parts.length isnt 3
    
    encoded = parts[2]
    compressed = new Buffer encoded, 'base64'

    zlib.inflateAsync compressed
    .then (decompressed) ->
      return decompressed.toString 'utf-8'
    