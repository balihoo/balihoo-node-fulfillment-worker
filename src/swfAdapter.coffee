'use strict'
aws = require 'aws-sdk'
Promise = require 'bluebird'
error = require './error'
activityStatus = require './activityStatus'

class SwfAdapter
  constructor: (@config) ->
    swfConfig =
      apiVersion: @config.apiVersion
      region: @config.region
      params:
        domain: @config.domain
        name: @config.name
        version: @config.version

    if @config.accessKeyId && @config.secretAccessKey
      swfConfig.accessKeyId = @config.accessKeyId
      swfConfig.secretAccessKey = @config.secretAccessKey

    @swf = Promise.promisifyAll(new aws.SWF(swfConfig), suffix:'CustomSuffix')


  ###
    Checks for the presence of the worker's activity type and if not found, registers it.

    @returns {Promise}
  ###
  ensureActivityTypeRegistered: ->
    describeParams =
      activityType:
        name: @config.name
        version: @config.version

    @swf.describeActivityTypeCustomSuffix describeParams
      .catch error.isUnknownResourceError, =>
        # Activity type doesn't exist, so register it
        @swf.registerActivityTypeCustomSuffix
          defaultTaskHeartbeatTimeout: @config.defaultTaskHeartbeatTimeout || '3900'
          defaultTaskScheduleToCloseTimeout: @config.defaultTaskScheduleToCloseTimeout || '3600'
          defaultTaskScheduleToStartTimeout: @config.defaultTaskScheduleToStartTimeout || '300'
          defaultTaskStartToCloseTimeout: @config.defaultTaskStartToCloseTimeout || '600'

  ###
    Polls for an activity task

    @returns {Promise}
  ###
  pollForActivityTaskCustomSuffix: ->
    @swf.pollForActivityTaskCustomSuffix
      taskList:
        name: this.config.name + this.config.version

  ###
    Sends result back to SWF

    @param {String} taskToken
    @param {Object} result
    @returns {Promise}
  ###
  respondWithWorkResult: (taskToken, result) ->
    @swf.respondActivityTaskCompletedCustomSuffix
      taskToken: taskToken
      result: result

  ###
    Cancels the task

    @param {String} taskToken
    @param {String} details
    @returns {Promise}
  ###
  cancelTask: (taskToken, details) ->
    @swf.respondActivityTaskCanceledCustomSuffix
      details: details
      taskToken: taskToken

  ###
    Fails the task

    @param {String} taskToken
    @param {String} details
    @returns {Promise}
  ###
  failTask: (taskToken, details) ->
    @swf.respondActivityTaskFailedCustomSuffix
      details: details
      reason: "" # Currently necessary because the fulfillment dashboard requires reason to be non-null
      taskToken: taskToken

  ###
    Send a task heartbeat. (prevent task timeout)

    @param {String} taskToken
    @param {String} details
    @returns {Promise}
  ###
  recordHeartbeat: (taskToken, details) ->
    @swf.recordActivityTaskHeartbeatCustomSuffix {taskToken, details}

module.exports = SwfAdapter
