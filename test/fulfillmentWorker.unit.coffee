'use strict'
assert = require 'assert'
aws = require 'aws-sdk'
sinon = require 'sinon'
Promise = require 'bluebird'
FulfillmentWorker = require '../lib/fulfillmentWorker'
activityStatus = require '../lib/activityStatus'
error = require '../lib/error'
mockDynamoDB = require './mocks/mockDynamoDB'
mockSWF = require './mocks/mockSWF'
mockSQS = require './mocks/mockSQS'
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
      workerStatusQueueName: "workerStatusTestQueue"
      updateIntervalMs: 1000
      parameterSchema: {}
      resultSchema: {}

  describe 'constructor', ->
    beforeEach ->
      sinon.stub aws, 'SQS', mockSQS
    afterEach ->
      aws.SQS.restore()

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
      assert.ok worker.uuid
      assert typeof worker.uuid is 'string'

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
    worker = null

    beforeEach ->
      sinon.stub aws, 'DynamoDB', mockDynamoDB
      sinon.stub aws, 'SWF', mockSWF
      sinon.stub aws, 'SQS', mockSQS
      worker = new FulfillmentWorker(config)

    context 'prior to polling for work', ->
      it 'checks for an existing ActivityType', (done) ->
        expectedParams =
          activityType:
            name: config.name
            version: config.version

        worker.swfAdapter.swf.pollForActivityTask = ->
          assert worker.swfAdapter.swf.describeActivityType.calledOnce
          assert worker.swfAdapter.swf.describeActivityType.calledWith expectedParams
          worker.stop()
          .then ->
            done()

        worker.workAsync -> {}

      context 'when the activity type is not found', ->
        it 'registers the activity type', (done) ->
          expectedParams =
            defaultTaskHeartbeatTimeout: config.defaultTaskHeartbeatTimeout
            defaultTaskScheduleToCloseTimeout: config.defaultTaskScheduleToCloseTimeout
            defaultTaskScheduleToStartTimeout: config.defaultTaskScheduleToStartTimeout
            defaultTaskStartToCloseTimeout: config.defaultTaskStartToCloseTimeout

          worker.swfAdapter.swf.describeActivityType = sinon.spy ->
            err = Error('Loud noises!')
            err.cause =
              code: 'UnknownResourceFault'
            throw err

          worker.swfAdapter.swf.pollForActivityTask = ->
            assert worker.swfAdapter.swf.registerActivityType.calledOnce
            assert worker.swfAdapter.swf.registerActivityType.calledWith expectedParams
            worker.stop()
            .then ->
              done()

          worker.workAsync -> {}

      context 'when an error other than UnknownResourceFault occurs', ->
        it 'rejects the promise with the error', (done) ->
          fakeError = new Error('Loud noises!')

          worker.swfAdapter.swf.describeActivityType = sinon.spy ->
            throw fakeError

          promise = worker.workAsync -> {}
          promise
          .catch (err) ->
            assert.strictEqual fakeError, err
            done()

    context 'when polling for work', ->
      it 'uses worker name + version as the task list', (done) ->
        expectedParams =
          taskList:
            name: config.name + config.version

        worker.swfAdapter.swf.pollForActivityTask = sinon.spy (params) ->
          assert.deepEqual(expectedParams, params)
          worker.stop()
          .then ->
            done()

        worker.workAsync -> {}

      context 'when there is no work to be done', ->
        it 'polls again', (done) ->
          callCount = 0
          worker.swfAdapter.swf.pollForActivityTask = (params, callback) ->
            callCount++

            if callCount == 2
              worker.stop()
                .then ->
                  done()

            callback null, {}

          worker.workAsync -> {}

      context 'when there is work to be done', ->
        expectedInput = null
        expectedToken = null
        expectedResult = null
        expectedSwfResult = null
        err = null

        beforeEach ->
          expectedToken = 'fakeToken'

          expectedInput =
            someKey: 'someValue'
            anotherKey:
              aSubKey: 1

          expectedResult =
            something: 'weeeee!'
            somethingElse: 5

          expectedSwfResult =
            status: activityStatus.success
            result: expectedResult

          fakeTask =
            taskToken: expectedToken
            input: JSON.stringify expectedInput

          errorDetails = 'Some extra error details'
          err = new Error('Loud noises!')
          err.details = errorDetails

          worker.swfAdapter.swf.pollForActivityTask = (params, callback) ->
            callback null, fakeTask

        it 'invokes the provided worker function with the task input', (done) ->
          worker.workAsync (input) ->
            assert.deepEqual expectedInput, input

            worker.stop()
            .then ->
              done()

          context 'when the worker function returns a result', ->
            it 'returns the result to simple workflow', (done) ->
              worker.swfAdapter.swf.respondActivityTaskCompleted = (params) ->
                assert.strictEqual expectedToken, params.taskToken
                assert.strictEqual params.result, JSON.stringify expectedSwfResult
                worker.stop()
                .then ->
                  done()

              worker.workAsync ->
                return expectedResult

          context 'when the worker function returns a promise that resolves', ->
            it 'returns the result to simple workflow', (done) ->
              worker.swfAdapter.swf.respondActivityTaskCompleted = (params) ->
                assert.strictEqual params.taskToken, expectedToken
                assert.strictEqual params.result, JSON.stringify expectedSwfResult
                worker.stop()
                .then ->
                  done()

              worker.workAsync ->
                return Promise.resolve expectedResult

          context 'when the worker function returns a promise that rejects', ->
            it 'fails the task', (done) ->
              expectedSwfResult =
                taskToken: expectedToken
                reason: ''
                details: JSON.stringify
                  status: activityStatus.error
                  notes: []
                  reason: err.message
                  result: err.message
                  trace: err.stack.split "\n"

              worker.swfAdapter.swf.respondActivityTaskFailed = (params) ->
                assert.deepEqual params, expectedSwfResult

                worker.stop()
                .then ->
                  done()

              worker.workAsync ->
                return Promise.reject err

          context 'when the worker function returns a promise that rejects with a FailTaskError', ->
            it 'fails the task', (done) ->
              failTaskError = new error.FailTaskError err.message, err.details, err.stack

              expectedSwfResult =
                taskToken: expectedToken
                reason: ''
                details: JSON.stringify
                  status: activityStatus.fatal
                  notes: []
                  reason: err.message
                  result: err.message
                  trace: err.stack.split "\n"

              worker.swfAdapter.swf.respondActivityTaskFailed = (params) ->
                assert.deepEqual params, expectedSwfResult

                worker.stop()
                .then ->
                  done()

              worker.workAsync ->
                return Promise.reject failTaskError

          context 'when the worker returns a promise which rejects with a CancelTaskError', ->
            it 'cancels the task', (done) ->
              cancelTaskError = new error.CancelTaskError err.message, err.details, err.stack

              expectedSwfResult =
                taskToken: expectedToken
                details: JSON.stringify
                  status: activityStatus.defer
                  notes: []
                  reason: err.message
                  result: err.message
                  trace: []

              worker.swfAdapter.swf.respondActivityTaskCanceled = (params) ->
                assert.deepEqual params, expectedSwfResult

                worker.stop()
                .then ->
                  done()

              worker.workAsync ->
                return Promise.reject cancelTaskError

          context 'when the worker function throws an error', ->
            it 'fails the task', (done) ->
              expectedSwfResult =
                taskToken: expectedToken
                reason: ''
                details: JSON.stringify
                  status: activityStatus.error
                  notes: []
                  reason: err.message
                  result: err.message
                  trace: err.stack.split "\n"

              worker.swfAdapter.swf.respondActivityTaskFailed = (params) ->
                assert.deepEqual params, expectedSwfResult

                worker.stop()
                .then ->
                  done()

              worker.workAsync ->
                throw err

          context 'when the worker function throws a FailTaskError', ->
            it 'fails the task', (done) ->
              failTaskError = new error.FailTaskError err.message, err.details, err.stack

              expectedSwfResult =
                taskToken: expectedToken
                reason: ''
                details: JSON.stringify
                  status: activityStatus.fatal
                  notes: []
                  reason: err.message
                  result: err.message
                  trace: err.stack.split "\n"

              worker.swfAdapter.swf.respondActivityTaskFailed = (params) ->
                assert.deepEqual params, expectedSwfResult

                worker.stop()
                .then ->
                  done()

              worker.workAsync ->
                throw failTaskError

          context 'when the worker function throws a CancelTaskError', ->
            it 'cancels the task', (done) ->
              cancelTaskError = new error.CancelTaskError err.message, err.details

              expectedSwfResult =
                taskToken: expectedToken
                details: JSON.stringify
                  status: activityStatus.defer
                  notes: []
                  reason: err.message
                  result: err.message
                  trace: []

              worker.swfAdapter.swf.respondActivityTaskCanceled = (params) ->
                assert.deepEqual params, expectedSwfResult

                worker.stop()
                .then ->
                  done()

              worker.workAsync ->
                throw cancelTaskError

    afterEach ->
      aws.DynamoDB.restore()
      aws.SWF.restore()
      aws.SQS.restore()

