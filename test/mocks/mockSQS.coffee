nodeLikeSuccessSpy = require('./utils').nodeLikeSuccessSpy

class mockSQS
  constructor: (@config) ->

  sendMessage: nodeLikeSuccessSpy()
  createQueue: nodeLikeSuccessSpy()

module.exports = mockSQS

