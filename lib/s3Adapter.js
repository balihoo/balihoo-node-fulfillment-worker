'use strict';
var Promise, S3Adapter, aws, error, url;

aws = require('aws-sdk');

Promise = require('bluebird');

url = require('url');

error = require('./error');

S3Adapter = (function() {
  function S3Adapter(config) {
    var s3Config;
    this.bucket = config.bucket;
    s3Config = {
      apiVersion: config.apiVersion,
      region: config.region,
      params: {
        Bucket: this.bucket
      }
    };
    if (config.accessKeyId && config.secretAccessKey) {
      s3Config.accessKeyId = config.accessKeyId;
      s3Config.secretAccessKey = config.secretAccessKey;
    }
    this.s3 = Promise.promisifyAll(new aws.S3(s3Config, {
      suffix: 'Promise'
    }));
  }

  S3Adapter.prototype.upload = function(key, data) {
    return this.s3.uploadAsync({
      Key: key,
      Body: data
    }).then((function(_this) {
      return function() {
        return "s3://" + _this.bucket + "/" + key;
      };
    })(this));
  };

  S3Adapter.prototype.download = function(s3Url) {
    var path, urlParts;
    urlParts = url.parse(s3Url);
    path = urlParts.path.replace(/^\//, '');
    return this.s3.getObjectAsync({
      Bucket: urlParts.host,
      Key: path
    });
  };

  return S3Adapter;

})();

module.exports = S3Adapter;
