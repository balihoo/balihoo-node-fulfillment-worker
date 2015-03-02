'use strict'
os = require 'os'
Promise = require 'bluebird'
workerStatusDao = require './workerStatusDao'

class WorkerStatusReporter
  constructor: (@instanceId, config) ->
    @domain = config.domain
    @name = config.name
    @version = config.version
    @specification =
      params: config.parameterSchema || {}
      result: config.resultSchema || {}

    @resolutionHistory = []
    @report = (config.dataWarehouseUser and config.dataWarehousePassword and
      config.dataWarehouseHost and config.dataWarehousePort and config.dataWarehouseDatabase)
    
    if @report
      @workerStatusDao = new workerStatusDao config
    
  init: ->
    Promise.try =>
      if @report
        @workerStatusDao.createFulfillmentActor @instanceId, @name, @version, @domain, @specification
      
  updateStatus: (status) ->
    Promise.try =>
      if @report
        @workerStatusDao.updateStatus @instanceId, status

  addResult: (resolution, result) ->
    Promise.try =>
      details = JSON.stringify result
        .substr 0, 30

      @resolutionHistory.push
        resolution: resolution,
        when: now(),
        details: details

      # Keep the last 20 only
      if @resolutionHistory.length > 20
        @resolutionHistory = @resolutionHistory.slice 1

      if @report
        @workerStatusDao.updateHistory @instanceId, @resolutionHistory

module.exports = WorkerStatusReporter