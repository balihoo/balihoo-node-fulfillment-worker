'use strict';
var Promise, SqsAdapter, WorkerStatusReporter, debounce, now, os, validate;

os = require('os');

Promise = require('bluebird');

debounce = require('debounce');

SqsAdapter = require('./sqsAdapter');

validate = require('./validate');

now = function() {
  return new Date().toISOString();
};

WorkerStatusReporter = (function() {
  function WorkerStatusReporter(uuid, config) {
    var updateInterval, updateStatus;
    this.uuid = uuid;
    validate.validateConfig(config, ['domain', 'name', 'version', 'workerStatusQueueName', 'parameterSchema', 'resultSchema']);
    this.domain = config.domain;
    this.name = config.name;
    this.version = config.version;
    this.qname = config.workerStatusQueueName;
    this.host = os.hostname();
    this.start = now();
    this.specification = {
      params: config.parameterSchema,
      result: config.resultSchema
    };
    this.resolutionHistory = [];
    this.sqsAdapter = new SqsAdapter(config);
    updateInterval = config.updateIntervalMs || 30000;
    updateStatus = (function(_this) {
      return function(status) {
        return _this.sqsAdapter.publish(_this.qname, JSON.stringify({
          Timestamp: now(),
          Message: {
            name: _this.name,
            start: _this.start,
            category: "worker",
            uuid: _this.uuid,
            spec: _this.specification,
            host: _this.host,
            domain: _this.domain,
            version: _this.version,
            status: status,
            history: _this.resolutionHistory
          }
        }));
      };
    })(this);
    this.updateStatus = debounce(updateStatus, updateInterval, true);
  }

  WorkerStatusReporter.prototype.init = function() {
    return this.updateStatus("Declaring");
  };

  WorkerStatusReporter.prototype.addResult = function(resolution, details) {
    return Promise["try"]((function(_this) {
      return function() {
        var jsonDetails;
        jsonDetails = JSON.stringify(details).substr(0, 30);
        _this.resolutionHistory.push({
          resolution: resolution,
          when: now(),
          details: jsonDetails
        });
        if (_this.resolutionHistory.length > 20) {
          return _this.resolutionHistory = _this.resolutionHistory.slice(1);
        }
      };
    })(this));
  };

  return WorkerStatusReporter;

})();

module.exports = WorkerStatusReporter;
