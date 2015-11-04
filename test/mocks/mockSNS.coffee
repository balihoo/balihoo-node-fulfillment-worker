nodeLikeSuccessSpy = require('./utils').nodeLikeSuccessSpy

class mockSNS
  constructor: (@config) ->

  publish: nodeLikeSuccessSpy()
  createTopic: nodeLikeSuccessSpy()

module.exports = mockSNS

