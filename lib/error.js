"use strict";

function inheritFromError(err) {
  err.prototype = new Error();
  err.prototype.constructor = err;
  return err;
}

function ConfigurationMissingError(propName) {
  this.name = "ConfigurationMissingError";
  this.missingProperty = propName;
  this.message = "Configuration object is missing required property " + propName + ".";
}

exports.ConfigurationMissingError = inheritFromError(ConfigurationMissingError);

function ConfigurationMustBeObjectError(type) {
  this.name = "ConfigurationMustBeObjectError";
  this.suppliedType = type;
  this.message = "Config must be of type object, " + type + " was supplied.";
}

exports.ConfigurationMustBeObjectError = inheritFromError(ConfigurationMustBeObjectError);

function CancelTaskError(innerErr) {
  this.name = "CancelTaskError";
  this.message = innerErr.message;
  this.innerErr = innerErr;
}

exports.CancelTaskError = inheritFromError(CancelTaskError);

exports.isCancelTaskError = function(err) {
  return (err instanceof CancelTaskError);
};

exports.isUnknownResourceError = function(err) {
  return (err && err.cause && err.cause.code === "UnknownResourceFault");
};