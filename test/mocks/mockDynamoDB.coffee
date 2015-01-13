sinon = require 'sinon'

mockFunc = ->
  return sinon.spy (item, callback) ->
    callback null, true

class mockDynamoDB
  constructor: (@config) ->

  putItem: mockFunc()
  updateItem: mockFunc()

module.exports = mockDynamoDB