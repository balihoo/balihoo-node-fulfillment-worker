'use strict'
uuid = require 'node-uuid'
Promise = require 'bluebird'
error = require './error'
SwfAdapter = require './swfAdapter'
WorkerStatusReporter = require './workerStatusReporter'
dataZipper = require './dataZipper'

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

    @swfAdapter = new SwfAdapter(config)
    @workerStatusReporter = new WorkerStatusReporter(@instanceId, config)
    @keepPolling = true

  workAsync: (workerFunc) ->
    handleTask = (task) =>
      @taskToken = task?.taskToken
      
      if @taskToken
        # Decompress the input if needed
        dataZipper.receive task.input
        .then (decompressedInput) ->
          # Parse the input into an object and do the work
          input = JSON.parse decompressedInput

          ###
          Wrap the worker call in Promise.resolve.  This allows workerFunc to return a simple value,
          a bluebird promise, or a promise from another A+ promise library.
          ###
          return Promise.resolve workerFunc input
      else
        # No work to be done
        return Promise.resolve()

    pollForWork = =>
      @workerStatusReporter.updateStatus 'active'

      return @swfAdapter.pollForActivityTaskAsync()
      .then handleTask
      .then dataZipper.deliver
      .then (workResult) =>
        if (workResult)
          return @swfAdapter.respondWithWorkResult @taskToken, workResult
          .then =>
            @workerStatusReporter.addResult 'Completed', workResult
      .catch error.CancelTaskError, (err) =>
        # A CancelTaskError results in a cancelled task
        return @swfAdapter.cancelTask @taskToken, err
        .then =>
          @workerStatusReporter.addResult 'Canceled', err.message
      .catch (err) =>
        if @taskToken
          # All other errors result in a failed task
          return @swfAdapter.failTask @taskToken, err
          .then =>
            @workerStatusReporter.addResult 'Failed', err.message
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