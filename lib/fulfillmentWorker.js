'use strict';
var ActivityProgressListener, FulfillmentWorker, Promise, S3Adapter, SwfAdapter, WorkerStatusReporter, activityStatus, dataZipper, error, nodeUuid, validate;

nodeUuid = require('node-uuid');

Promise = require('bluebird');

error = require('./error');

SwfAdapter = require('./swfAdapter');

S3Adapter = require('./s3Adapter');

WorkerStatusReporter = require('./workerStatusReporter');

dataZipper = require('./dataZipper');

activityStatus = require('./activityStatus');

validate = require('./validate');

ActivityProgressListener = require('./activityProgressListener');

FulfillmentWorker = (function() {
  function FulfillmentWorker(config) {
    var s3Adapter;
    validate.validateConfig(config, ['region', 'domain', 'name', 'version']);
    this.uuid = nodeUuid.v4();
    config.apiVersion = '2015-01-07';
    this.name = config.name;
    this.version = config.version;
    this.swfAdapter = new SwfAdapter(config);
    s3Adapter = new S3Adapter(config);
    this.dataZipper = new dataZipper.DataZipper(s3Adapter);
    this.workerStatusReporter = new WorkerStatusReporter(this.uuid, config);
    this.keepPolling = true;
    this.completedTasks = 0;
    this.canceledTasks = 0;
    this.failedTasks = 0;
    this.logger = config.logger || console;
  }

  FulfillmentWorker.prototype.workAsync = function(workerFunc) {
    var handleError, handleTask, pollForWork;
    handleError = (function(_this) {
      return function(err) {
        var ref, status;
        err.workerName = _this.name;
        err.workerVersion = _this.version;
        _this.logger.error(err);
        status = activityStatus.error;
        if (err instanceof error.CancelTaskError) {
          status = activityStatus.defer;
        } else if (err instanceof error.FailTaskError) {
          status = activityStatus.fatal;
        }
        return _this.dataZipper.deliver({
          status: status,
          notes: [],
          reason: err.message,
          result: err.message,
          trace: ((ref = err.stack) != null ? ref.split("\n") : void 0) || []
        }).then(function(details) {
          if (err instanceof error.CancelTaskError) {
            _this.canceledTasks++;
            _this.swfAdapter.cancelTask(_this.taskToken, details);
            return _this.workerStatusReporter.addResult('Canceled', details);
          } else {
            _this.failedTasks++;
            _this.swfAdapter.failTask(_this.taskToken, details);
            return _this.workerStatusReporter.addResult('Failed', details);
          }
        });
      };
    })(this);
    handleTask = (function(_this) {
      return function(task) {
        _this.taskToken = task != null ? task.taskToken : void 0;
        if (_this.taskToken) {
          return _this.dataZipper.receive(task.input).then(function(decompressedInput) {
            var context, createProgressListener, input, recordHeartbeat;
            input = JSON.parse(decompressedInput);
            recordHeartbeat = function(details) {
              return _this.swfAdapter.recordHeartbeat(_this.taskToken, details);
            };
            createProgressListener = function(interval, streamOpts) {
              return new ActivityProgressListener(interval, recordHeartbeat, streamOpts);
            };
            context = {
              recordHeartbeat: recordHeartbeat,
              createProgressListener: createProgressListener,
              workflowExecution: task.workflowExecution
            };

            /*
            Wrap the worker call in Promise.resolve.  This allows workerFunc to return a simple value,
            a bluebird promise, or a promise from another A+ promise library.
             */
            return Promise.resolve(workerFunc(input, context));
          }).then(function(workResult) {
            return {
              status: activityStatus.success,
              result: workResult
            };
          });
        } else {
          return Promise.resolve();
        }
      };
    })(this);
    pollForWork = (function(_this) {
      return function() {
        _this.workerStatusReporter.updateStatus("Polling " + _this.completedTasks + ":" + _this.failedTasks + ":" + _this.canceledTasks);
        return _this.swfAdapter.pollForActivityTaskAsync().then(handleTask).then(_this.dataZipper.deliver).then(function(workResult) {
          if (workResult) {
            _this.completedTasks++;
            _this.swfAdapter.respondWithWorkResult(_this.taskToken, workResult);
            return _this.workerStatusReporter.addResult('Completed', workResult);
          }
        })["catch"](handleError)["finally"](function() {
          if (_this.keepPolling) {
            return pollForWork();
          }
        });
      };
    })(this);
    return this.swfAdapter.ensureActivityTypeRegistered().then((function(_this) {
      return function() {
        return _this.workerStatusReporter.init();
      };
    })(this)).then(pollForWork);
  };

  FulfillmentWorker.prototype.stop = function() {
    this.keepPolling = false;
    return this.workerStatusReporter.updateStatus('Stopping...');
  };

  return FulfillmentWorker;

})();

module.exports = FulfillmentWorker;

module.exports.S3Adapter = S3Adapter;

module.exports.dataZipper = dataZipper;
