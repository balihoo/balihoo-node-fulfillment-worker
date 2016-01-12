assert = require 'assert'
sinon = require 'sinon'
aws = require 'aws-sdk'
mockSQS = require './mocks/mockSQS'
WorkerStatusReporter = require '../lib/workerStatusReporter'
error = require '../lib/error'
Promise = require 'bluebird'

config = undefined
uuid = undefined

createStubbedWorkerStatusReporter = ->
  w = new WorkerStatusReporter uuid, config
  w.sqsAdapter.sqs.createQueueAsync = sinon.spy ->
    Promise.resolve QueueUrl: "barncarnage"

  w.sqsAdapter.sqs.sendMessageAsync = sinon.spy (params) ->
    assert.strictEqual params.QueueUrl, "barncarnage"
    
  w

describe 'workerStatus unit tests', ->
  beforeEach ->
    config =
      region: 'fakeRegion'
      accessKeyId: 'fakeAccessKeyId'
      secretAccessKey: 'fakeSecretAccessKey'
      domain: 'fakeDomain'
      name: 'fakeWorkerName'
      version: 'fakeWorkerVersion'
      workerStatusQueueName: "workerStatusTestQueue"
      parameterSchema: {}
      resultSchema: {}
      apiVersion: "1-1-1900"
      updateIntervalMs: 200
    uuid = "SOMEUUIDSTRING"

  describe 'constructor', ->
    beforeEach ->
      sinon.stub aws, 'SQS', mockSQS
    afterEach ->
      aws.SQS.restore()

    it 'Requires a config', ->
      try
        new WorkerStatusReporter()
        assert.fail 'Expected a ConfigurationMustBeObjectError.'
      catch err
        assert err instanceof error.ConfigurationMustBeObjectError
        assert.strictEqual err.suppliedType, 'undefined'

    it 'properly constructs the worker', ->
      w = new WorkerStatusReporter uuid, config
      assert aws.SQS.calledOnce
      assert.deepEqual w.specification.params, config.parameterSchema
      assert.deepEqual w.specification.result, config.resultSchema

    it 'Declares a worker on init', ->
      w = new WorkerStatusReporter uuid, config
      w.updateStatus = sinon.spy (params) ->
        assert.strictEqual params, "Declaring"
      w.init -> {}

  describe 'updateStatus', ->
    beforeEach ->
      sinon.stub aws, 'SQS', mockSQS
    afterEach ->
      aws.SQS.restore()
    it 'pushes the expected message to SQS', ->
      w = createStubbedWorkerStatusReporter()

      w.updateStatus("stuff").then ->
        assert w.sqsAdapter.sqs.sendMessageAsync.calledOnce

    context 'when called more frequently than updateIntervalMs', ->
      it 'only pushes one message to SQS', ->
        w = createStubbedWorkerStatusReporter()
        w.updateStatus("stuff")
        .delay (config.updateIntervalMs / 2)
        .then ->
          w.updateStatus("stuff")
        .then ->
          assert w.sqsAdapter.sqs.sendMessageAsync.calledOnce

    context 'when called less frequently than updateIntervalMs', ->
      it 'pushes one message to SQS for each call', ->
        w = createStubbedWorkerStatusReporter()

        w.updateStatus("stuff")
        .delay (config.updateIntervalMs * 2)
        .then ->
          w.updateStatus("stuff")
        .then ->
          assert w.sqsAdapter.sqs.sendMessageAsync.calledTwice