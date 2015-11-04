assert = require 'assert'
sinon = require 'sinon'
aws = require 'aws-sdk'
mockSNS = require './mocks/mockSNS'
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
      workerStatusTopic: "workerStatus"
      parameterSchema: {}
      resultSchema: {}
      apiVersion: "1-1-1900"
    uuid = "SOMEUUIDSTRING"

  describe 'constructor', ->
    beforeEach ->
      sinon.stub aws, 'SNS', mockSNS
    afterEach ->
      aws.SNS.restore()

    it 'Requires a config', ->
      try
        new WorkerStatusReporter()
        assert.fail 'Expected a ConfigurationMustBeObjectError.'
      catch err
        assert err instanceof error.ConfigurationMustBeObjectError
        assert.strictEqual err.suppliedType, 'undefined'

    it 'properly constructs the worker', ->
      w = new WorkerStatusReporter(uuid, config)
      assert aws.SNS.calledOnce
      assert.deepEqual w.specification.params, config.parameterSchema
      assert.deepEqual w.specification.result, config.resultSchema

    it 'Declares a worker on init', ->
      w = new WorkerStatusReporter(uuid, config)
      status = undefined
      w.updateStatus = sinon.spy (params) ->
        assert.strictEqual params, "Declaring"
      w.init -> {}

    it 'pushes the expected message to SNS', ->
      w = new WorkerStatusReporter(uuid, config)
      w.snsAdapter.sns.createTopicAsync = sinon.spy (params) ->
        Promise.try =>
          TopicArn: "barncarnage"

      published = 0
      w.snsAdapter.sns.publishAsync = sinon.spy (params) ->
        assert.strictEqual params.TopicArn, "barncarnage"
        published += 1

      tlen = -> Object.keys(w.snsAdapter.topicArns).length
      assert.strictEqual tlen(), 0
      w.updateStatus("stuff").then ->
        assert.strictEqual tlen(), 1
        w.updateStatus("stuff").then ->
          assert.strictEqual tlen(), 1
          assert.strictEqual published, 2

    it 'adds a resolution', ->
      w = new WorkerStatusReporter(uuid, config)
      expectedHistory = '{"Things":"stuff"}'
      w.addResult('Completed', Things: "stuff").then ->
        assert.strictEqual w.resolutionHistory[0].details, expectedHistory
      publishedHistory = undefined
      w.snsAdapter.sns.publishAsync = sinon.spy (params) ->
        msg = JSON.parse params.Message
        publishedHistory = msg.history[0].details
      w.updateStatus("stuff").then ->
        assert.strictEqual publishedHistory, expectedHistory
