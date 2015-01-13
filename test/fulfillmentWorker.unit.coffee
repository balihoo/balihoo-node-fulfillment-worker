'use strict'
assert = require 'assert'
aws = require 'aws-sdk'
sinon = require 'sinon'
FulfillmentWorker = require '../lib/fulfillmentWorker'
error = require '../lib/error'
mockDynamoDB = require './mocks/mockDynamoDB'
mockSWF = require './mocks/mockSWF'
config = undefined

testRequiresConfigParameter = (config, propName) ->
  delete config[propName]

  try
    new FulfillmentWorker config
    assert.fail 'Expected a ConfigurationMissingError.'
  catch err
    assert err instanceof error.ConfigurationMissingError
    assert.deepEqual err.missingProperties, [propName]
  return

describe 'FulfillmentWorker unit tests', ->
  beforeEach ->
    config =
      region: 'fakeRegion'
      accessKeyId: 'fakeAccessKeyId'
      secretAccessKey: 'fakeSecretAccessKey'
      domain: 'fakeDomain'
      name: 'fakeWorkerName'
      version: 'fakeWorkerVersion'
      defaultTaskHeartbeatTimeout: 4000
      defaultTaskScheduleToCloseTimeout: 400
      defaultTaskScheduleToStartTimeout: 700
      defaultTaskStartToCloseTimeout: 4700

  describe 'constructor', ->
    it 'Requires a config', ->
      try
        new FulfillmentWorker()
        assert.fail 'Expected a ConfigurationMustBeObjectError.'
      catch err
        assert err instanceof error.ConfigurationMustBeObjectError
        assert.strictEqual err.suppliedType, 'undefined'

    it 'Requires that the config be an object', ->
      try
        new FulfillmentWorker('not an object')
        assert.fail 'Expected a ConfigurationMustBeObjectError.'
      catch err
        assert err instanceof error.ConfigurationMustBeObjectError
        assert.strictEqual err.suppliedType, 'string'

    it 'Requires config.region', ->
      testRequiresConfigParameter config, 'region'

    it 'Requires config.domain', ->
      testRequiresConfigParameter config, 'domain'

    it 'Requires config.workerName', ->
      testRequiresConfigParameter config, 'name'

    it 'Requires config.workerVersion', ->
      testRequiresConfigParameter config, 'version'

    it 'Adds an API version to config', ->
      new FulfillmentWorker(config)
      assert.ok config.apiVersion
      assert typeof config.apiVersion is 'string'

    it 'Creates an instance ID', ->
      worker = new FulfillmentWorker(config)
      assert.ok worker.instanceId
      assert typeof worker.instanceId is 'string'

    it 'Creates an AWS DynamoDB instance', ->
      sinon.stub aws, 'DynamoDB', mockDynamoDB
      worker = new FulfillmentWorker(config)

      expectedConfig =
        accessKeyId: config.accessKeyId
        secretAccessKey: config.secretAccessKey
        apiVersion: config.apiVersion
        region: config.region
        params:
          TableName: config.tableName

      assert aws.DynamoDB.calledOnce
      assert.deepEqual expectedConfig, worker.workerStatusReporter.dynamoAdapter.dynamo.config
      aws.DynamoDB.restore()

    it 'Creates an AWS SWF instance', ->
      sinon.stub aws, 'SWF', mockSWF
      worker = new FulfillmentWorker(config)

      expectedConfig =
        accessKeyId: config.accessKeyId
        secretAccessKey: config.secretAccessKey
        apiVersion: config.apiVersion
        region: config.region
        params:
          domain: config.domain
          name: config.name
          version: config.version

      assert aws.SWF.calledOnce
      assert.deepEqual expectedConfig, worker.swfAdapter.swf.config
      aws.SWF.restore()

  describe 'workAsync', ->
    beforeEach ->
      sinon.stub aws, 'DynamoDB', mockDynamoDB
      sinon.stub aws, 'SWF', mockSWF

    it 'checks for an existing ActivityType', ->
      expectedParams =
        activityType:
          name: config.name
          version: config.version

      worker = new FulfillmentWorker(config)
      worker.workAsync -> {}

      assert worker.swfAdapter.swf.describeActivityType.calledOnce
      assert worker.swfAdapter.swf.describeActivityType.calledWith expectedParams

    context 'when the activity type is not found', ->
      it 'registers the activity type', ->
        expectedParams =
          defaultTaskHeartbeatTimeout: config.defaultTaskHeartbeatTimeout
          defaultTaskScheduleToCloseTimeout: config.defaultTaskScheduleToCloseTimeout
          defaultTaskScheduleToStartTimeout: config.defaultTaskScheduleToStartTimeout
          defaultTaskStartToCloseTimeout: config.defaultTaskStartToCloseTimeout

    afterEach ->
      aws.DynamoDB.restore()
      aws.SWF.restore()

