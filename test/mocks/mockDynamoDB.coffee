nodeLikeSuccessSpy = require('./utils').nodeLikeSuccessSpy

class mockDynamoDB
  constructor: (@config) ->

  putItem: nodeLikeSuccessSpy()
  updateItem: nodeLikeSuccessSpy()

module.exports = mockDynamoDB