'use strict'
os = require 'os'
Promise = require 'bluebird'
SqsAdapter = require './sqsAdapter'
validate = require './validate'

now = ->
  return new Date().toISOString()

class WorkerStatusReporter
  constructor: (@uuid, config) ->
    validate.validateConfig(config, ['domain', 'name', 'version', 'workerStatusQueueName', 'parameterSchema', 'resultSchema'])
    @domain = config.domain
    @name = config.name
    @version = config.version
    @qname = config.workerStatusQueueName
    @host = os.hostname()
    @start = now()
    @specification =
      params: config.parameterSchema
      result: config.resultSchema
    @resolutionHistory = []
    @sqsAdapter = new SqsAdapter config

  init: ->
    @updateStatus "Declaring"

  addResult: (resolution, details) ->
    Promise.try =>
      jsonDetails = JSON.stringify details
      .substr 0, 30

      @resolutionHistory.push
        resolution: resolution,
        when: now(),
        details: jsonDetails

      # Keep the last 20 only
      if @resolutionHistory.length > 20
        @resolutionHistory = @resolutionHistory.slice 1

  updateStatus: (status) ->
    @sqsAdapter.publish @qname, JSON.stringify
      Timestamp: now(),
      Message:
        name: @name
        start: @start
        category: "worker"
        uuid: @uuid
        spec: @specification
        host: @host
        domain: @domain
        version: @version
        status: status
        history: @resolutionHistory

module.exports = WorkerStatusReporter
