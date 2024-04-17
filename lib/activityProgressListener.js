var ActivityProgressListener, Promise, Stream, epoch,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Stream = require('stream');

Promise = require('bluebird');

epoch = function() {
  return (new Date).getTime();
};


/*
  Utility stream writer that sends a heartbeat every once
  in a while to report activity progress.
 */

module.exports = ActivityProgressListener = (function(superClass) {
  extend(ActivityProgressListener, superClass);


  /*
    @param {object} streamOpts Options to be passed to parent Stream class.
    @param {object} interval Number of seconds between before sending a heartbeat.
    @param {function} heartbeatAsync Function that can be invoked to send heartbeat asynchronously.
   */

  function ActivityProgressListener(interval, heartbeatFunc, streamOpts) {
    this.interval = interval;
    this.heartbeatFunc = heartbeatFunc;
    if (streamOpts == null) {
      streamOpts = {};
    }
    this.handler = bind(this.handler, this);
    ActivityProgressListener.__super__.constructor.call(this, streamOpts);
    this.processed = 0;
    this.last = epoch();
  }


  /*
    Emits a heartbeat record request and update last timestamp.
   */

  ActivityProgressListener.prototype.notify = function() {
    this.last = epoch();
    return this.heartbeatFunc("Progress: " + this.processed + " elements processed");
  };


  /*
    Handles a data event, whether invoked through _write or on 'data' event.
    @returns {boolean} true if a heartbeat has been recorded, otherwise false.
   */

  ActivityProgressListener.prototype.handler = function() {
    this.processed++;
    if (epoch() - this.last > this.interval * 1000) {
      return this.notify().then(function() {
        return true;
      });
    } else {
      return Promise.resolve(false);
    }
  };

  ActivityProgressListener.prototype._write = function(chunk, enc, cb) {
    return this.handler().then(function() {
      return cb(null, chunk);
    })["catch"]((function(_this) {
      return function(err) {
        return _this.emit('error', err);
      };
    })(this));
  };

  return ActivityProgressListener;

})(Stream.Writable);
