'use strict'
os = require 'os'
Promise = require 'bluebird'
WorkerStatusDao = require './workerStatusDao'

now = ->
  return new Date().toISOString()

class WorkerStatusReporter
  constructor: (@instanceId, config) ->
    @domain = config.domain
    @name = config.name
    @version = config.version
    @specification =
      params: config.parameterSchema or {}
      result: config.resultSchema or {}

    @resolutionHistory = []
    @report = (config.workerStatusDb?.username and config.workerStatusDb?.password and
      config.workerStatusDb?.host and config.workerStatusDb?.name)
    
    if @report
      @workerStatusDao = new WorkerStatusDao config.workerStatusDb
    
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