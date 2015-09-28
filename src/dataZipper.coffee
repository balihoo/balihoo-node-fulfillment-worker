crypto = require 'crypto'
zlib = require 'zlib'
Promise = require 'bluebird'
startsWith = require('./utils').startsWith
Promise.promisifyAll zlib

request = require 'request'
request = request.defaults
  timeout: 20000
  pool: false # Use the default node request agent
Promise.promisifyAll request

exports.MAX_RESULT_SIZE = MAX_RESULT_SIZE = 32768
exports.ZIP_PREFIX = ZIP_PREFIX = 'FF-ZIP'
exports.URL_PREFIX = URL_PREFIX = 'FF-URL'
exports.SEPARATOR = SEPARATOR = ':'

s3dir = 'retain_30_180/zipped-ff'

getHash = (data) ->
  md5sum = crypto.createHash 'md5'
  md5sum.update data
  md5sum.digest 'hex'

byteLength = (str) ->
  Buffer.byteLength str, 'utf8'

zip = (data) ->
  zlib.deflateAsync data
  .then (compressed) ->
    encoded = new Buffer compressed
    .toString 'base64'

    "#{ZIP_PREFIX}#{SEPARATOR}#{byteLength data}#{SEPARATOR}#{encoded}"

unzip = (data) ->
  parts = data.split SEPARATOR
  throw new Error "Malformed zip data"  if parts.length isnt 3

  encoded = parts[2]
  compressed = new Buffer encoded, 'base64'

  zlib.inflateAsync compressed
  .then (decompressed) ->
    return decompressed.toString 'utf-8'

storeInS3 = (data, s3Adapter) ->
  hash = getHash data

  s3Adapter.upload "#{s3dir}/#{hash}.ff", data
  .then (uri) ->
    "#{URL_PREFIX}#{SEPARATOR}#{hash}#{SEPARATOR}#{uri}"
    
getFromUrl = (input, s3Adapter) ->
  parts = input.split SEPARATOR
  throw new Error "Malformed URL #{input}"  if parts.length isnt 4
  
  protocol = parts[2]
  path = parts[3]
  uri = "#{protocol}:#{path}"
  
  if protocol is 's3'
    s3Adapter.download uri
    .then (s3Result) ->
      s3Result.Body?.toString 'utf-8'
      
  else if protocol is 'http' or protocol is 'https'
    request.getAsync uri
    .spread (_, body) ->
      body
  else
    throw new Error "Unknown protocol #{protocol}"
  
exports.DataZipper = class DataZipper
  constructor: (@s3Adapter) ->

  deliver: (workResult) =>
    Promise.try =>
      return null  unless workResult?
      
      stringResult = JSON.stringify workResult

      if byteLength(stringResult) < MAX_RESULT_SIZE
        return stringResult

      # Result is too big, compress and base64 encode it
      zip stringResult
      .then (zipResult) =>
        if byteLength(zipResult) < MAX_RESULT_SIZE
          return zipResult

        # Zipped result is still too big, so put it in S3
        storeInS3 zipResult, @s3Adapter

  receive: (input) =>
    Promise.try =>
      if typeof input is 'string'
        if startsWith input, ZIP_PREFIX
          unzip input
        else if startsWith input, URL_PREFIX
          getFromUrl input, @s3Adapter
          .then @receive
        else
          # It isn't an ZIP or URL, so just return the string
          return input
      else
        # It isn't a string, so return it
        return input
