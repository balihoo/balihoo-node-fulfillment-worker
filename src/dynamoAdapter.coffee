'use strict'
aws = require 'aws-sdk'
toDynamoItem = require('dynamodb-data-types').AttributeValue.wrap
toDynamoPutUpdates = require('dynamodb-data-types').AttributeValueUpdate.put
Promise = require 'bluebird'
error = require './error'

class DynamoAdapter
  constructor: (config) ->
    dynamoConfig =
      apiVersion: config.apiVersion
      region: config.region
      params:
        TableName: config.tableName

    if config.accessKeyId && config.secretAccessKey
      dynamoConfig.accessKeyId = config.accessKeyId
      dynamoConfig.secretAccessKey = config.secretAccessKey

    @dynamo = Promise.promisifyAll new aws.DynamoDB(dynamoConfig)

  putItem: (item) ->
    return @dynamo.putItemAsync
      Item: toDynamoItem item

  updateItem: (key, partialItem) ->
    return @dynamo.updateItemAsync
      Key: toDynamoItem key
      AttributeUpdates: toDynamoPutUpdates partialItem

module.exports = DynamoAdapter