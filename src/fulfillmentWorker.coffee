'use strict'
uuid = require 'node-uuid'
Promise = require 'bluebird'
error = require './error'
SwfAdapter = require './swfAdapter'
S3Adapter = require './s3Adapter'
WorkerStatusReporter = require './workerStatusReporter'
dataZipper = require './dataZipper'
activityStatus = require './activityStatus'

validateConfig = (config) ->
  if typeof config isnt 'object'
    throw new error.ConfigurationMustBeObjectError(typeof config)

  requiredConfigProperties = ['region', 'domain', 'name', 'version']

  missingProperties = (prop for prop in requiredConfigProperties when !config[prop]?)

  if missingProperties.length
    throw new error.ConfigurationMissingError(missingProperties)

class FulfillmentWorker
  constructor: (config) ->
    validateConfig config
    
    @instanceId = uuid.v4()
    config.apiVersion = '2015-01-07'

    @swfAdapter = new SwfAdapter config
    s3Adapter = new S3Adapter config
    @dataZipper = new dataZipper.DataZipper s3Adapter
    @workerStatusReporter = new WorkerStatusReporter @instanceId, config
    @keepPolling = true

  workAsync: (workerFunc) ->
    handleError = (err) =>
      status = activityStatus.error

      if err instanceof error.CancelTaskError
        status = activityStatus.defer
      else if err instanceof error.FailTaskError
        status = activityStatus.fatal

      @dataZipper.deliver
        status: status
        notes: error.buildNotes err
      .then (details) =>
        if err instanceof error.CancelTaskError
          @swfAdapter.cancelTask @taskToken, details
        else
          @swfAdapter.failTask @taskToken, details

    handleTask = (task) =>
      @taskToken = task?.taskToken
      
      if @taskToken
        # Decompress the input if needed
        @dataZipper.receive task.input
        .then (decompressedInput) ->
          # Parse the input into an object and do the work
          input = JSON.parse decompressedInput

          ###
          Wrap the worker call in Promise.resolve.  This allows workerFunc to return a simple value,
          a bluebird promise, or a promise from another A+ promise library.
          ###
          Promise.resolve workerFunc input
        .then (workResult) ->
          status: activityStatus.success
          result: workResult
      else
        # No work to be done
        return Promise.resolve()
  
    pollForWork = =>
      @workerStatusReporter.updateStatus 'active'

      return @swfAdapter.pollForActivityTaskAsync()
      .then handleTask
      .then @dataZipper.deliver
      .then (workResult) =>
        if (workResult)
          return @swfAdapter.respondWithWorkResult @taskToken, workResult
          .then =>
            @workerStatusReporter.addResult 'Completed', workResult
      .catch handleError
      .finally =>
        if @keepPolling
          return pollForWork()

    return @swfAdapter.ensureActivityTypeRegistered()
    .then =>
      return @workerStatusReporter.init()
    .then pollForWork

  stop: ->
    @keepPolling = false
    return @workerStatusReporter.updateStatus 'stopped'

module.exports = FulfillmentWorker

module.exports.S3Adapter = S3Adapter
module.exports.dataZipper = dataZipper