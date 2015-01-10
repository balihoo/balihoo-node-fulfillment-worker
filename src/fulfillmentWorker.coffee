'use strict'
uuid = require 'node-uuid'
Promise = require 'bluebird'
error = require '../lib/error'
SwfAdapter = require './swfAdapter'
workerStatusReporter = require '../lib/workerStatusReporter'

validateConfig = (config) ->
  if typeof config isnt 'object'
    throw new error.ConfigurationMustBeObjectError(typeof config)

  requiredConfigProperties = ['region', 'domain', 'name', 'version']

  missingProperties = (prop for prop in requiredConfigProperties when typeof config[prop] is 'undefined')

  if missingProperties.length
    throw new error.ConfigurationMissingError(missingProperties)

class FulfillmentWorker
  constructor: (@config) ->
    validateConfig @config
    @config.apiVersion = '2015-01-07'
    @config.instanceId = uuid.v4()
    console.log(@config.instanceId)
    @swfAdapter = new SwfAdapter(@config)
    @workerStatusReporter = new workerStatusReporter @config

  workAsync: (workerFunc) ->
    workerStatusReporter = @workerStatusReporter
    swfAdapter = @swfAdapter

    parseInput = Promise.method (input) ->
      return JSON.parse(input)

    handleTask = (task) ->
      if (task && task.taskToken)
        # Parse the input into an object and do the work
        return parseInput task.input
          .then (input) ->
            ###
            Wrap the worker  in Promise.resolve.  This allows workerFunc to return a simple value,
            a bluebird promise, or a promise from another A+ promise library.
            ###
            return Promise.resolve workerFunc(input)
      else
        # No work to be done
        return Promise.resolve()

    pollForWork = () ->
      workerStatusReporter.updateStatus('Polling')
      taskToken = null

      return swfAdapter.pollForActivityTaskAsync()
        .then (task) ->
          taskToken = task.token
          return task
        .then handleTask
        .then (workResult) ->
          if (workResult)
            return swfAdapter.respondWithWorkResult taskToken, workResult
        .catch error.isCancelTaskError, (err) ->
          # A CancelTaskError results in a cancelled task
          return swfAdapter.cancelTask(taskToken, err)
        .catch (err) ->
          # All other errors result in a failed task
          if taskToken
            return swfAdapter.failTask(taskToken, err)
        .finally(pollForWork)


    return swfAdapter.ensureActivityTypeRegistered()
      .then pollForWork

module.exports = FulfillmentWorker