assert = require 'assert'
sinon = require 'sinon'
aws = require 'aws-sdk'
mockSQS = require './mocks/mockSQS'
WorkerStatusReporter = require '../lib/workerStatusReporter'
error = require '../lib/error'
Promise = require 'bluebird'

config = undefined
uuid = undefined

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
      w = new WorkerStatusReporter(uuid, config)
      assert aws.SQS.calledOnce
      assert.deepEqual w.specification.params, config.parameterSchema
      assert.deepEqual w.specification.result, config.resultSchema

    it 'Declares a worker on init', ->
      w = new WorkerStatusReporter(uuid, config)
      status = undefined
      w.updateStatus = sinon.spy (params) ->
        assert.strictEqual params, "Declaring"
      w.init -> {}

    it 'pushes the expected message to SQS', ->
      w = new WorkerStatusReporter(uuid, config)
      w.sqsAdapter.sqs.createQueueAsync = sinon.spy (params) ->
        Promise.try =>
          QueueUrl: "barncarnage"

      w.sqsAdapter.sqs.sendMessageAsync = sinon.spy (params) ->
        assert.strictEqual params.QueueUrl, "barncarnage"

      w.updateStatus("stuff").then ->
        w.updateStatus("stuff").then ->
          assert w.sqsAdapter.sqs.sendMessageAsync.calledTwice

    it 'adds a resolution', ->
      w = new WorkerStatusReporter(uuid, config)
      expectedHistory = '{"Things":"stuff"}'
      w.addResult('Completed', Things: "stuff").then ->
        assert.strictEqual w.resolutionHistory[0].details, expectedHistory
      publishedHistory = undefined
      w.sqsAdapter.sqs.sendMessageAsync = sinon.spy (params) ->
        msg = JSON.parse params.MessageBody
        publishedHistory = msg.Message.history[0].details
      w.updateStatus("stuff").then ->
        assert.strictEqual publishedHistory, expectedHistory
