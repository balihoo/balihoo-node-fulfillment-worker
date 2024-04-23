'use strict';
var Promise, SwfAdapter, activityStatus, aws, error;

aws = require('aws-sdk');

Promise = require('bluebird');

error = require('./error');

activityStatus = require('./activityStatus');

SwfAdapter = (function() {
  function SwfAdapter(config) {
    var swfConfig;
    this.config = config;
    swfConfig = {
      apiVersion: this.config.apiVersion,
      region: this.config.region,
      params: {
        domain: this.config.domain,
        name: this.config.name,
        version: this.config.version
      }
    };
    if (this.config.accessKeyId && this.config.secretAccessKey) {
      swfConfig.accessKeyId = this.config.accessKeyId;
      swfConfig.secretAccessKey = this.config.secretAccessKey;
    }
    this.swf = Promise.promisifyAll(new aws.SWF(swfConfig), {
      suffix: 'CustomSuffix'
    });
  }


  /*
    Checks for the presence of the worker's activity type and if not found, registers it.
  
    @returns {Promise}
   */

  SwfAdapter.prototype.ensureActivityTypeRegistered = function() {
    var describeParams;
    describeParams = {
      activityType: {
        name: this.config.name,
        version: this.config.version
      }
    };
    return this.swf.describeActivityTypeCustomSuffix(describeParams)["catch"](error.isUnknownResourceError, (function(_this) {
      return function() {
        return _this.swf.registerActivityTypeCustomSuffix({
          defaultTaskHeartbeatTimeout: _this.config.defaultTaskHeartbeatTimeout || '3900',
          defaultTaskScheduleToCloseTimeout: _this.config.defaultTaskScheduleToCloseTimeout || '3600',
          defaultTaskScheduleToStartTimeout: _this.config.defaultTaskScheduleToStartTimeout || '300',
          defaultTaskStartToCloseTimeout: _this.config.defaultTaskStartToCloseTimeout || '600'
        });
      };
    })(this));
  };


  /*
    Polls for an activity task
  
    @returns {Promise}
   */

  SwfAdapter.prototype.pollForActivityTaskCustomSuffix = function() {
    return this.swf.pollForActivityTaskCustomSuffix({
      taskList: {
        name: this.config.name + this.config.version
      }
    });
  };


  /*
    Sends result back to SWF
  
    @param {String} taskToken
    @param {Object} result
    @returns {Promise}
   */

  SwfAdapter.prototype.respondWithWorkResult = function(taskToken, result) {
    return this.swf.respondActivityTaskCompletedCustomSuffix({
      taskToken: taskToken,
      result: result
    });
  };


  /*
    Cancels the task
  
    @param {String} taskToken
    @param {String} details
    @returns {Promise}
   */

  SwfAdapter.prototype.cancelTask = function(taskToken, details) {
    return this.swf.respondActivityTaskCanceledCustomSuffix({
      details: details,
      taskToken: taskToken
    });
  };


  /*
    Fails the task
  
    @param {String} taskToken
    @param {String} details
    @returns {Promise}
   */

  SwfAdapter.prototype.failTask = function(taskToken, details) {
    return this.swf.respondActivityTaskFailedCustomSuffix({
      details: details,
      reason: "",
      taskToken: taskToken
    });
  };


  /*
    Send a task heartbeat. (prevent task timeout)
  
    @param {String} taskToken
    @param {String} details
    @returns {Promise}
   */

  SwfAdapter.prototype.recordHeartbeat = function(taskToken, details) {
    return this.swf.recordActivityTaskHeartbeatCustomSuffix({
      taskToken: taskToken,
      details: details
    });
  };

  return SwfAdapter;

})();

module.exports = SwfAdapter;
