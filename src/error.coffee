'use strict'
exports.ConfigurationMissingError = class ConfigurationMissingError extends Error
  constructor: (@missingProperties) ->
    @message = 'Configuration object is missing the following required properties: ' + @missingProperties.toString() + '.'

exports.ConfigurationMustBeObjectError = class ConfigurationMustBeObjectError extends Error
  constructor: (@suppliedType) ->
    @message = 'Config must be of type object, ' + @suppliedType + ' was supplied.'

exports.FailTaskError = class FailTaskError extends Error
  constructor: (@message, @details, @stack) ->

exports.CancelTaskError = class CancelTaskError extends Error
  constructor: (@message, @details) ->

exports.isUnknownResourceError = (err) ->
  err and err.cause and err.cause.code is 'UnknownResourceFault'
