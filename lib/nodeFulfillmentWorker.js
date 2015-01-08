"use strict";
var uuid = require('node-uuid');
var error = require("./error");
var swfAdapter = require("./swfAdapter");

/**
 * Ensures that config is an object which contains all required properties
 *
 * @param {Object} config
 *
 * @throws error.ConfigurationMustBeObjectError
 * @throws error.ConfigurationMissingError
 */
var validateConfig = function(config) {
  var requiredConfigProperties = ["accessKeyId", "secretAccessKey", "region", "domain", "name", "version"];

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
 * Creates a NodeFulfillmentWorker
 *
 * @param {Object} config
 * @constructor
 */
function NodeFulfillmentWorker(config) {
  validateConfig(config);

  config.apiVersion = "2015-01-07";
  config.instanceId = uuid.v4();

  this.config = config;

  this.swfAdapter = new swfAdapter(config);
}

/**
 * Connects to the Balihoo Fulfillment environment and starts polling for work
 *
 * @param {Function} workerFunc The function to call when work is received
 */
NodeFulfillmentWorker.prototype.work = function(workerFunc) {
  var swfAdapter = this.swfAdapter;

  var pollForWork = function pollForWork() {
    console.log("Checking for work.");
    return swfAdapter.pollForActivityTaskAsync()
      .then(function (task) {
        console.log("Working task " + task.taskToken + ": " + JSON.stringify(task));
        if (task && task.taskToken) {
          var input;
          try {
            input = JSON.parse(task.input);
          } catch(err) {
            // TODO: Fail the task
            return pollForWork()
          }
          // Do the work
          console.log("Calling worker function with input: " + task.input);
          return workerFunc(input)
            .then(function(result) {
              console.log("Got work result: " + JSON.stringify(result));
              // TODO: Return the result to SWF
              return pollForWork();
            });
            // TODO: catch cancel errors and send cancel response to SWF
            // TODO: catch all other errors and return a fail response to SWF
        } else {
          // No work was found, check again
          console.log("No work found.");
          return pollForWork();
        }
      });
  };

  return swfAdapter.ensureActivityTypeRegistered()
    .then(pollForWork)
};

module.exports = NodeFulfillmentWorker;