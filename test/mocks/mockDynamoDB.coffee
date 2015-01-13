sinon = require 'sinon'

nodeLikeSuccessSpy = ->
  return sinon.spy (item, callback) ->
    callback null, true

class mockDynamoDB
  constructor: (@config) ->

  putItem: nodeLikeSuccessSpy()
  updateItem: nodeLikeSuccessSpy()

module.exports = mockDynamoDB