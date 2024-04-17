'use strict';
var error;

error = require('./error');

exports.validateConfig = function(config, fields) {
  var missingProperties, prop, requiredConfigProperties;
  if (typeof config !== 'object') {
    throw new error.ConfigurationMustBeObjectError(typeof config);
  }
  requiredConfigProperties = fields;
  missingProperties = (function() {
    var i, len, results;
    results = [];
    for (i = 0, len = requiredConfigProperties.length; i < len; i++) {
      prop = requiredConfigProperties[i];
      if (config[prop] == null) {
        results.push(prop);
      }
    }
    return results;
  })();
  if (missingProperties.length) {
    throw new error.ConfigurationMissingError(missingProperties);
  }
};
