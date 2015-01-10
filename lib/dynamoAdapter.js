var aws = require('aws-sdk');
var toDynamoItem = require('dynamodb-data-types').AttributeValue.wrap;
var toDynamoPutUpdates = require('dynamodb-data-types').AttributeValueUpdate.put;
var Promise = require('bluebird');
var error = require('./error');

/**
 * Creates a new DynamoAdapter which wraps the aws.DynamoDB service
 *
 * @param {Object} config
 * @constructor
 */
function DynamoAdapter(config) {
  this.config = config;

  this.dynamo = Promise.promisifyAll(new aws.DynamoDB({
      apiVersion: config.apiVersion,
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
      region: config.region,
      params: {
        TableName: config.tableName
      }
    })
  );
}

DynamoAdapter.prototype.putItem = function putItem(item) {
  return this.dynamo.putItemAsync({
    Item: toDynamoItem(item)
  });
};

DynamoAdapter.prototype.updateItem = function putItem(key, partialItem) {
  return this.dynamo.updateItemAsync({
    Key: toDynamoItem(key),
    AttributeUpdates: toDynamoPutUpdates(partialItem)
  });
};

module.exports = DynamoAdapter;