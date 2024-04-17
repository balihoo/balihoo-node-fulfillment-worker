'use strict';
var CancelTaskError, ConfigurationMissingError, ConfigurationMustBeObjectError, FailTaskError,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

exports.ConfigurationMissingError = ConfigurationMissingError = (function(superClass) {
  extend(ConfigurationMissingError, superClass);

  function ConfigurationMissingError(missingProperties) {
    this.missingProperties = missingProperties;
    this.message = 'Configuration object is missing the following required properties: ' + this.missingProperties.toString() + '.';
  }

  return ConfigurationMissingError;

})(Error);

exports.ConfigurationMustBeObjectError = ConfigurationMustBeObjectError = (function(superClass) {
  extend(ConfigurationMustBeObjectError, superClass);

  function ConfigurationMustBeObjectError(suppliedType) {
    this.suppliedType = suppliedType;
    this.message = 'Config must be of type object, ' + this.suppliedType + ' was supplied.';
  }

  return ConfigurationMustBeObjectError;

})(Error);

exports.FailTaskError = FailTaskError = (function(superClass) {
  extend(FailTaskError, superClass);

  function FailTaskError(message, details, stack) {
    this.message = message;
    this.details = details;
    this.stack = stack;
  }

  return FailTaskError;

})(Error);

exports.CancelTaskError = CancelTaskError = (function(superClass) {
  extend(CancelTaskError, superClass);

  function CancelTaskError(message, details) {
    this.message = message;
    this.details = details;
  }

  return CancelTaskError;

})(Error);

exports.isUnknownResourceError = function(err) {
  return err && err.cause && err.cause.code === 'UnknownResourceFault';
};
