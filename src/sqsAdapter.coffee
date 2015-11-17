'use strict'
aws = require 'aws-sdk'
Promise = require 'bluebird'
error = require './error'
validate = require './validate'

class SqsAdapter
  constructor: (@config) ->
    validate.validateConfig(@config, ['region', 'domain', 'name', 'version', 'apiVersion'])
    sqsConfig =
      apiVersion: @config.apiVersion
      region: @config.region
      params:
        domain: @config.domain
        name: @config.name
        version: @config.version

    if @config.accessKeyId && @config.secretAccessKey
      sqsConfig.accessKeyId = @config.accessKeyId
      sqsConfig.secretAccessKey = @config.secretAccessKey

    @sqs = Promise.promisifyAll new aws.SQS sqsConfig
    @topicArns = {}

  ###
    Pushes a message on the specified queue

    @param {String} queuename
    @param {String} msg
    @returns {Promise}
  ###
  publish: (qname, msg) ->
    @sqs.createQueueAsync
      QueueName: qname
      Attributes:
        VisibilityTimeout: "1"
        MessageRetentionPeriod: "60"
    .then (response) =>
      @sqs.sendMessageAsync
        MessageBody: msg
        QueueUrl: response.QueueUrl

module.exports = SqsAdapter
