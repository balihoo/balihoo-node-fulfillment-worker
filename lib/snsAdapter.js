'use strict';
var Promise, SnsAdapter, aws, error, validate;

aws = require('aws-sdk');

Promise = require('bluebird');

error = require('./error');

validate = require('./validate');

SnsAdapter = (function() {
  function SnsAdapter(config) {
    var snsConfig;
    this.config = config;
    validate.validateConfig(this.config, ['region', 'domain', 'name', 'version', 'apiVersion']);
    snsConfig = {
      apiVersion: this.config.apiVersion,
      region: this.config.region,
      params: {
        domain: this.config.domain,
        name: this.config.name,
        version: this.config.version
      }
    };
    if (this.config.accessKeyId && this.config.secretAccessKey) {
      snsConfig.accessKeyId = this.config.accessKeyId;
      snsConfig.secretAccessKey = this.config.secretAccessKey;
    }
    this.sns = Promise.promisifyAll(new aws.SNS(snsConfig), {
      suffix: 'CustomSuffix'
    });
    this.topicArns = {};
  }


  /*
    Publishes a message on the specified topic
  
    @param {String} topic
    @param {String} msg
    @returns {Promise}
   */

  SnsAdapter.prototype.publish = function(topic, msg) {
    var createTopic;
    createTopic = this.sns.createTopicCustomSuffix({
      Name: topic
    }).then(function(response) {
      return response.TopicArn;
    });
    return Promise["try"]((function(_this) {
      return function() {
        return _this.topicArns[topic] || (_this.topicArns[topic] = createTopic);
      };
    })(this)).then((function(_this) {
      return function(topicArn) {
        return _this.sns.publishCustomSuffix({
          Message: msg,
          TopicArn: topicArn
        });
      };
    })(this));
  };

  return SnsAdapter;

})();

module.exports = SnsAdapter;
