'use strict'

error = require './error'

exports.validateConfig = (config, fields) ->
  if typeof config isnt 'object'
    throw new error.ConfigurationMustBeObjectError(typeof config)

  requiredConfigProperties = fields

  missingProperties = (prop for prop in requiredConfigProperties when !config[prop]?)

  if missingProperties.length
    throw new error.ConfigurationMissingError(missingProperties)


