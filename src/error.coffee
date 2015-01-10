'use strict'
class ConfigurationMissingError extends Error
  constructor: (missingProps) ->
    @missingProperties = missingProps
    @message = 'Configuration object is missing the following required properties: ' + missingProps.toString() + '.'

class ConfigurationMustBeObjectError extends Error
  constructor: (type) ->
    @suppliedType = type
    @message = 'Config must be of type object, ' + type + ' was supplied.'

class CancelTaskError extends Error
  constructor: (err) ->
    @message = err.message
    @innerErr = err

exports.ConfigurationMissingError = ConfigurationMissingError
exports.ConfigurationMustBeObjectError = ConfigurationMustBeObjectError
exports.CancelTaskError = CancelTaskError

exports.isCancelTaskError = (err) ->
  err instanceof CancelTaskError

exports.isUnknownResourceError = (err) ->
  err and err.cause and err.cause.code is 'UnknownResourceFault'