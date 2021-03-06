'use strict'
aws = require 'aws-sdk'
Promise = require 'bluebird'
url = require 'url'
error = require './error'

class S3Adapter
  constructor: (config) ->
    @bucket = config.bucket
    
    s3Config =
      apiVersion: config.apiVersion
      region: config.region
      params:
        Bucket: @bucket

    if config.accessKeyId && config.secretAccessKey
      s3Config.accessKeyId = config.accessKeyId
      s3Config.secretAccessKey = config.secretAccessKey

    @s3 = Promise.promisifyAll new aws.S3 s3Config

  upload: (key, data) ->
    @s3.uploadAsync
      Key: key
      Body: data
    .then =>
      "s3://#{@bucket}/#{key}"

  download: (s3Url) ->
    urlParts = url.parse s3Url
    path = urlParts.path.replace /^\//, '' # Remove leading /
    
    @s3.getObjectAsync
      Bucket: urlParts.host
      Key: path

module.exports = S3Adapter