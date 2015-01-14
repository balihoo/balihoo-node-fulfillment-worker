'use strict'
class ConfigurationMissingError extends Error
  constructor: (@missingProperties) ->
    @message = 'Configuration object is missing the following required properties: ' + @missingProperties.toString() + '.'

class ConfigurationMustBeObjectError extends Error
  constructor: (@suppliedType) ->
    @message = 'Config must be of type object, ' + @suppliedType + ' was supplied.'

class CancelTaskError extends Error
  constructor: (@innerErr) ->
    @message = @innerErr.message

exports.ConfigurationMissingError = ConfigurationMissingError
exports.ConfigurationMustBeObjectError = ConfigurationMustBeObjectError
exports.CancelTaskError = CancelTaskError

exports.isUnknownResourceError = (err) ->
  err and err.cause and err.cause.code is 'UnknownResourceFault'