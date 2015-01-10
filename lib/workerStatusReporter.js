"use strict";
var os = require("os");
var Promise = require("bluebird");
var dynamoAdapter = require("./dynamoAdapter");

var WORKER_STATUS_TABLE = "fulfillment_worker_status";

var now = function now() {
  return new Date().toISOString()
};

/**
 * Creates a WorkerStatusReporter
 *
 * @param {Object} config
 * @constructor
 */
function WorkerStatusReporter(config) {
  config.tableName = WORKER_STATUS_TABLE;

  this.instanceId = config.instanceId;
  this.hostAddress = os.hostname();
  this.domain = config.domain;
  this.name = config.name;
  this.version = config.version;
  this.specification = {
    parameters: config.parameterSchema || {},
    result: config.resultSchema || {}
  };

  this.resolutionHistory = [];

  this.dynamoAdapter = new dynamoAdapter(config);

  // Put the entire worker status item on initialization
  this.dynamoAdapter.putItem({
    instance: this.instanceId,
    hostAddress: os.hostname(),
    domain: this.domain,
    activityName: this.name,
    activityVersion: this.version,
    specification: JSON.stringify(this.specification),
    status: "Initializing",
    resolutionHistory: JSON.stringify(this.resolutionHistory),
    start: now(),
    last: now()
  });
}

WorkerStatusReporter.prototype.updateStatus = function(status) {
  this.dynamoAdapter.updateItem({ instance: this.instanceId }, {status: status, last: now() });
};

WorkerStatusReporter.prototype.addResult = function(resolution, details) {
  this.resolutionHistory.push({ resolution: resolution, when: now(), details: details });

  // Keep the last 20 only
  if (this.resolutionHistory.length > 20) {
    this.resolutionHistory = this.resolutionHistory.slice(1);
  }
  this.dynamoAdapter.updateItem(
    { instance: this.instanceId },
    {
      resolutionHistory: JSON.stringify(this.resolutionHistory),
      last: now()
    });
};

module.exports = WorkerStatusReporter;