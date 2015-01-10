'use strict'
aws = require 'aws-sdk'
Promise = require 'bluebird'
error = require './error'

class SwfAdapter
  constructor: (@config) ->
    @swf = Promise.promisifyAll new aws.SWF
      apiVersion: config.apiVersion,
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
      region: config.region,
      params:
        domain: config.domain,
        name: config.name,
        version: config.version

  ###
    Checks for the presence of the worker's activity type and if not found, registers it.

    @returns {Promise}
  ###
  ensureActivityTypeRegistered: () ->
    swf = @swf
    config = @config

    describeParams =
      activityType:
        name: config.name,
        version: config.version

    return swf.describeActivityTypeAsync describeParams
    .catch error.isUnknownResourceError, () ->
      # Activity type doesn't exist, so register it
      return swf.registerActivityTypeAsync
        defaultTaskHeartbeatTimeout: config.defaultTaskHeartbeatTimeout || 3900,
        defaultTaskScheduleToCloseTimeout: config.defaultTaskScheduleToCloseTimeout || 3600,
        defaultTaskScheduleToStartTimeout: config.defaultTaskScheduleToStartTimeout || 300,
        defaultTaskStartToCloseTimeout: config.defaultTaskStartToCloseTimeout || 600

  ###
    Polls for an activity task

    @returns {Promise}
  ###
  pollForActivityTaskAsync: () ->
    return @swf.pollForActivityTaskAsync
      taskList:
        name: this.config.name + this.config.version

  ###
    Sends result back to SWF

    @param {String} taskToken
    @param {Object} result
    @returns {Promise}
  ###
  respondWithWorkResult: (taskToken, result) ->
    return this.swf.respondActivityTaskCompletedAsync
      taskToken: taskToken,
      result: JSON.stringify result

  ###
    Cancels the task

    @param {String} taskToken
    @param {Error} err
    @returns {Promise}
  ###
  cancelTask: (taskToken, err) ->
    return this.swf.respondActivityTaskCanceledAsync
      taskToken: taskToken,
      details: err.message

  ###
    Fails the task

    @param {String} taskToken
    @param {Error} err
    @returns {Promise}
  ###
  failTask: (taskToken, err) ->
    return this.swf.respondActivityTaskFailedAsync
      taskToken: taskToken,
      reason: err.message,
      details: err.stack

module.exports = SwfAdapter