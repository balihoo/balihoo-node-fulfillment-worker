sinon = require 'sinon'

exports.config = null

exports.mock =
  putItemAsync: sinon.spy ->
    return Promise.resolve()

  updateItemAsync: sinon.spy ->
    return Promise.resolve()

exports.mockConstructor = (config) ->
  exports.config = config
  return exports.mock

exports.reset = ->
  exports.config = null
  exports.mock.putItemAsync.reset()
  exports.mock.updateItemAsync.reset()
