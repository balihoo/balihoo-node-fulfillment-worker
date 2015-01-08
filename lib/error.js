"use strict";

function ConfigurationMissingError(propName) {
  this.name = "ConfigurationMissingError";
  this.missingProperty = propName;
  this.message = "Configuration object is missing required property " + propName + ".";
}

ConfigurationMissingError.prototype = Error.prototype;

exports.ConfigurationMissingError = ConfigurationMissingError;

function ConfigurationMustBeObjectError(type) {
  this.name = "ConfigurationMustBeObjectError";
  this.suppliedType = type;
  this.message = "Config must be of type object, " + type + " was supplied.";
}

ConfigurationMustBeObjectError.prototype = Error.prototype;

exports.ConfigurationMustBeObjectError = ConfigurationMustBeObjectError;

function BogusError() {
  this.name = "BogusError";
  this.message = "blergh!";
}

exports.BogusError = BogusError;

exports.isUnknownResourceError = function(err) {
  return (err && err.cause && err.cause.code === "UnknownResourceFault");
};