'use strict';
var Promise, SqsAdapter, aws, error, validate;

aws = require('aws-sdk');

Promise = require('bluebird');

error = require('./error');

validate = require('./validate');

SqsAdapter = (function() {
  function SqsAdapter(config) {
    var sqsConfig;
    this.config = config;
    validate.validateConfig(this.config, ['region', 'domain', 'name', 'version', 'apiVersion']);
    sqsConfig = {
      apiVersion: this.config.apiVersion,
      region: this.config.region,
      params: {
        domain: this.config.domain,
        name: this.config.name,
        version: this.config.version
      }
    };
    if (this.config.accessKeyId && this.config.secretAccessKey) {
      sqsConfig.accessKeyId = this.config.accessKeyId;
      sqsConfig.secretAccessKey = this.config.secretAccessKey;
    }
    this.sqs = Promise.promisifyAll(new aws.SQS(sqsConfig, {
      suffix: 'Promise'
    }));
    this.topicArns = {};
  }


  /*
    Pushes a message on the specified queue
  
    @param {String} queuename
    @param {String} msg
    @returns {Promise}
   */

  SqsAdapter.prototype.publish = function(qname, msg) {
    return this.sqs.createQueueAsync({
      QueueName: qname,
      Attributes: {
        VisibilityTimeout: "1",
        MessageRetentionPeriod: "60"
      }
    }).then((function(_this) {
      return function(response) {
        return _this.sqs.sendMessageAsync({
          MessageBody: msg,
          QueueUrl: response.QueueUrl
        });
      };
    })(this));
  };

  return SqsAdapter;

})();

module.exports = SqsAdapter;
