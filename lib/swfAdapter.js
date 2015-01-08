var aws = require('aws-sdk');
var Promise = require('bluebird');
var error = require('./error');

/**
 * Wraps the aws.SWF service
 *
 * @param {Object} config
 * @constructor
 */
function SwfAdapter(config) {
  this.config = config;

  this.swfService = Promise.promisifyAll(new aws.SWF({
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
      region: config.region,

      params: {
        domain: config.domain,
        name: config.name,
        version: config.version
      }
    })
  );
}

/**
 * Checks for the presence of the worker's activity type and if not found, registers it.
 *
 * @returns {Promise}
 */
SwfAdapter.prototype.ensureActivityTypeRegistered = function registerActivityType() {
  var swfService = this.swfService;
  var config = this.config;

  var describeParams = {
    activityType: {
      name: this.config.name,
      version: this.config.version }
  };

  return swfService.describeActivityTypeAsync(describeParams)
    .catch(error.isUnknownResourceError, function() {
      // Activity type doesn't exist, so register it
      return swfService.registerActivityTypeAsync({
        defaultTaskHeartbeatTimeout: config.defaultTaskHeartbeatTimeout || 3900,
        defaultTaskScheduleToCloseTimeout: config.defaultTaskScheduleToCloseTimeout || 3600,
        defaultTaskScheduleToStartTimeout: config.defaultTaskScheduleToStartTimeout || 300,
        defaultTaskStartToCloseTimeout: config.defaultTaskStartToCloseTimeout || 600
      });
    });
};

SwfAdapter.prototype.pollForActivityTaskAsync = function pollForActivityTaskAsync() {
  return this.swfService.pollForActivityTaskAsync({
    taskList: {
      name: this.config.name + this.config.version
    }
  })
};

module.exports = SwfAdapter;