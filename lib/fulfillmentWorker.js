"use strict";
var uuid = require('node-uuid');
var Promise = require('bluebird');
var error = require("./error");
var swfAdapter = require("./swfAdapter");
var workerStatusReporter = require("./workerStatusReporter");

/**
 * Ensures that config is an object which contains all required properties
 *
 * @param {Object} config
 *
 * @throws error.ConfigurationMustBeObjectError
 * @throws error.ConfigurationMissingError
 */
var validateConfig = function(config) {
  var requiredConfigProperties = ["region", "domain", "name", "version"];

  if (typeof config !== "object") {
    throw new error.ConfigurationMustBeObjectError(typeof config);
  }
  requiredConfigProperties.forEach(function(propName) {
    if (typeof config[propName] === "undefined") {
      throw new error.ConfigurationMissingError(propName);
    }
  });
};

/**
 * Creates a FulfillmentWorker
 *
 * @param {Object} config
 * @constructor
 */
function FulfillmentWorker(config) {
  validateConfig(config);

  config.apiVersion = "2015-01-07";
  config.instanceId = uuid.v4();

  this.config = config;

  this.swfAdapter = new swfAdapter(config);
  this.workerStatusReporter = new workerStatusReporter(config);
}

/**
 * Connects to the Balihoo Fulfillment environment and starts polling for work
 *
 * @param {Function} workerFunc The function to call when work is received
 * @returns {Promise}
 */
FulfillmentWorker.prototype.workAsync = function(workerFunc) {
  var swfAdapter = this.swfAdapter;
  var workerStatusReporter = this.workerStatusReporter;

  var parseInput = Promise.method(function(input) {
    return JSON.parse(input);
  });

  var handleTask = function(task) {
    if (task && task.taskToken) {
      // Parse the input into an object and do the work
      return parseInput(task.input)
        .then(function(input) {
          // Wrap the worker function in Promise.resolve.  This allows workerFunc to return a simple value,
          // a bluebird promise, or a promise from another A+ promise library.
          return Promise.resolve(workerFunc(input));
        });
    } else {
      // No work to be done
      return Promise.resolve();
    }
  };

  var pollForWork = function pollForWork() {
    workerStatusReporter.updateStatus("Polling");
    var taskToken = null;

    return swfAdapter.pollForActivityTaskAsync()
      .then(function(task) {
        taskToken = task.token;
        return task;
      })
      .then(handleTask)
      .then(function(workResult) {
        if (workResult) {
          return swfAdapter.respondWithWorkResult(taskToken, workResult);
        }
      })
      .catch(error.isCancelTaskError, function(err) {
        // A CancelTaskError results in a cancelled task
        return swfAdapter.cancelTask(taskToken, err);
      })
      .catch(function(err) {
        // All other errors result in a failed task
        if (taskToken) {
          return swfAdapter.failTask(taskToken, err);
        }
      })
      .finally(pollForWork)
  };

  return swfAdapter.ensureActivityTypeRegistered()
    .then(pollForWork)
};

module.exports = FulfillmentWorker;