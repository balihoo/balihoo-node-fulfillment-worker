sinon = require 'sinon'

class mockDynamoDB
  constructor: (@config) ->

  putItem: sinon.spy ->
    return true

  updateItem: sinon.spy ->
    return true

module.exports = mockDynamoDB