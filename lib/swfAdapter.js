var aws = require('aws-sdk');
var Promise = require('bluebird');
var error = require('./error');

/**
 * Creates a new SwfAdapter which wraps the aws.SWF service
 *
 * @param {Object} config
 * @constructor
 */
function SwfAdapter(config) {
  this.config = config;

  this.swf = Promise.promisifyAll(new aws.SWF({
      apiVersion: config.apiVersion,
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
  var swf = this.swf;
  var config = this.config;

  var describeParams = {
    activityType: {
      name: this.config.name,
      version: this.config.version }
  };

  return swf.describeActivityTypeAsync(describeParams)
    .catch(error.isUnknownResourceError, function() {
      // Activity type doesn't exist, so register it
      return swf.registerActivityTypeAsync({
        defaultTaskHeartbeatTimeout: config.defaultTaskHeartbeatTimeout || 3900,
        defaultTaskScheduleToCloseTimeout: config.defaultTaskScheduleToCloseTimeout || 3600,
        defaultTaskScheduleToStartTimeout: config.defaultTaskScheduleToStartTimeout || 300,
        defaultTaskStartToCloseTimeout: config.defaultTaskStartToCloseTimeout || 600
      });
    });
};

/**
 * Polls for an activity task
 * @returns {Promise}
 */
SwfAdapter.prototype.pollForActivityTaskAsync = function pollForActivityTaskAsync() {
  return this.swf.pollForActivityTaskAsync({
    taskList: {
      name: this.config.name + this.config.version
    }
  })
};

/**
 * Sends result back to SWF
 *
 * @param {String} taskToken
 * @param {Object} result
 * @returns {Promise}
 */
SwfAdapter.prototype.respondWithWorkResult = function respondWithWorkResult(taskToken, result) {
  return this.swf.respondActivityTaskCompletedAsync({
    taskToken: taskToken,
    result: JSON.stringify(result)
  });
};

/**
 * Cancels the task
 *
 * @param {String} taskToken
 * @param {Error} err
 * @returns {Promise}
 */
SwfAdapter.prototype.cancelTask = function respondWithWorkResult(taskToken, err) {
  return this.swf.respondActivityTaskCanceledAsync({
    taskToken: taskToken,
    details: err.message
  });
};

/**
 * Fails the task
 *
 * @param {Object} taskToken
 * @param {Error} err
 * @returns {Promise}
 */
SwfAdapter.prototype.failTask = function respondWithWorkResult(taskToken, err) {
  return this.swf.respondActivityTaskFailedAsync({
    taskToken: taskToken,
    reason: err.message,
    details: err.stack
  });
};

module.exports = SwfAdapter;