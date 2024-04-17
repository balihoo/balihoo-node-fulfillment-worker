var DataZipper, MAX_RESULT_SIZE, Promise, SEPARATOR, URL_PREFIX, ZIP_PREFIX, byteLength, crypto, getFromUrl, getHash, request, s3dir, startsWith, storeInS3, unzip, zip, zlib,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

crypto = require('crypto');

zlib = require('zlib');

Promise = require('bluebird');

startsWith = require('./utils').startsWith;

Promise.promisifyAll(zlib);

request = require('request');

request = request.defaults({
  timeout: 20000,
  pool: false
});

Promise.promisifyAll(request);

exports.MAX_RESULT_SIZE = MAX_RESULT_SIZE = 32768;

exports.ZIP_PREFIX = ZIP_PREFIX = 'FF-ZIP';

exports.URL_PREFIX = URL_PREFIX = 'FF-URL';

exports.SEPARATOR = SEPARATOR = ':';

s3dir = 'retain_30_180/zipped-ff';

getHash = function(data) {
  var md5sum;
  md5sum = crypto.createHash('md5');
  md5sum.update(data);
  return md5sum.digest('hex');
};

byteLength = function(str) {
  return Buffer.byteLength(str, 'utf8');
};

zip = function(data) {
  return zlib.deflateAsync(data).then(function(compressed) {
    var encoded;
    encoded = new Buffer(compressed).toString('base64');
    return "" + ZIP_PREFIX + SEPARATOR + (byteLength(data)) + SEPARATOR + encoded;
  });
};

unzip = function(data) {
  var compressed, encoded, parts;
  parts = data.split(SEPARATOR);
  if (parts.length !== 3) {
    throw new Error("Malformed zip data");
  }
  encoded = parts[2];
  compressed = new Buffer(encoded, 'base64');
  return zlib.inflateAsync(compressed).then(function(decompressed) {
    return decompressed.toString('utf-8');
  });
};

storeInS3 = function(data, s3Adapter) {
  var hash;
  hash = getHash(data);
  return s3Adapter.upload(s3dir + "/" + hash + ".ff", data).then(function(uri) {
    return "" + URL_PREFIX + SEPARATOR + hash + SEPARATOR + uri;
  });
};

getFromUrl = function(input, s3Adapter) {
  var parts, path, protocol, uri;
  parts = input.split(SEPARATOR);
  if (parts.length !== 4) {
    throw new Error("Malformed URL " + input);
  }
  protocol = parts[2];
  path = parts[3];
  uri = protocol + ":" + path;
  if (protocol === 's3') {
    return s3Adapter.download(uri).then(function(s3Result) {
      var ref;
      return (ref = s3Result.Body) != null ? ref.toString('utf-8') : void 0;
    });
  } else if (protocol === 'http' || protocol === 'https') {
    return request.getAsync(uri).spread(function(_, body) {
      return body;
    });
  } else {
    throw new Error("Unknown protocol " + protocol);
  }
};

exports.DataZipper = DataZipper = (function() {
  function DataZipper(s3Adapter1) {
    this.s3Adapter = s3Adapter1;
    this.receive = bind(this.receive, this);
    this.deliver = bind(this.deliver, this);
  }

  DataZipper.prototype.deliver = function(workResult) {
    return Promise["try"]((function(_this) {
      return function() {
        var stringResult;
        if (workResult == null) {
          return null;
        }
        stringResult = JSON.stringify(workResult);
        if (byteLength(stringResult) < MAX_RESULT_SIZE) {
          return stringResult;
        }
        return zip(stringResult).then(function(zipResult) {
          if (byteLength(zipResult) < MAX_RESULT_SIZE) {
            return zipResult;
          }
          return storeInS3(zipResult, _this.s3Adapter);
        });
      };
    })(this));
  };

  DataZipper.prototype.receive = function(input) {
    return Promise["try"]((function(_this) {
      return function() {
        if (typeof input === 'string') {
          if (startsWith(input, ZIP_PREFIX)) {
            return unzip(input);
          } else if (startsWith(input, URL_PREFIX)) {
            return getFromUrl(input, _this.s3Adapter).then(_this.receive);
          } else {
            return input;
          }
        } else {
          return input;
        }
      };
    })(this));
  };

  return DataZipper;

})();
