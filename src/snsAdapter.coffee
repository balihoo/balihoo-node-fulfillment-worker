'use strict'
aws = require 'aws-sdk'
Promise = require 'bluebird'
error = require './error'
validate = require './validate'

class SnsAdapter
  constructor: (@config) ->
    validate.validateConfig(@config, ['region', 'domain', 'name', 'version', 'apiVersion'])
    snsConfig =
      apiVersion: @config.apiVersion
      region: @config.region
      params:
        domain: @config.domain
        name: @config.name
        version: @config.version

    if @config.accessKeyId && @config.secretAccessKey
      snsConfig.accessKeyId = @config.accessKeyId
      snsConfig.secretAccessKey = @config.secretAccessKey

    @sns = Promise.promisifyAll new aws.SNS snsConfig
    @topicArns = {}

  ###
    Publishes a message on the specified topic

    @param {String} topic
    @param {String} msg
    @returns {Promise}
  ###
  publish: (topic, msg) ->
    createTopic = @sns.createTopicAsync Name: topic
      .then (response) ->
        response.TopicArn

    Promise.try =>
      @topicArns[topic] or @topicArns[topic] = createTopic
    .then (topicArn) =>
      @sns.publishAsync
        Message: msg
        TopicArn: topicArn

module.exports = SnsAdapter
