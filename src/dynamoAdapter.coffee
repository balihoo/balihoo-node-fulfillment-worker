'use strict'
aws = require 'aws-sdk'
toDynamoItem = require('dynamodb-data-types').AttributeValue.wrap
toDynamoPutUpdates = require('dynamodb-data-types').AttributeValueUpdate.put
Promise = require 'bluebird'
error = require './error'

class DynamoAdapter
  constructor: (@config) ->
    @config = config
    @dynamo = Promise.promisifyAll new aws.DynamoDB
      apiVersion: @config.apiVersion
      accessKeyId: @config.accessKeyId
      secretAccessKey: @config.secretAccessKey
      region: @config.region
      params:
        TableName: @config.tableName

  putItem: (item) ->
    @dynamo.putItemAsync
      Item: toDynamoItem item

  updateItem: (key, partialItem) ->
    @dynamo.updateItemAsync
      Key: toDynamoItem key
      AttributeUpdates: toDynamoPutUpdates partialItem

module.exports = DynamoAdapter