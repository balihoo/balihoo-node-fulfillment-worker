nodeLikeSuccessSpy = require('./utils').nodeLikeSuccessSpy

class mockSWF
  constructor: (@config) ->

  describeActivityType: nodeLikeSuccessSpy()
  registerActivityType: nodeLikeSuccessSpy()
  pollForActivityTask: nodeLikeSuccessSpy()
  respondActivityTaskCompleted: nodeLikeSuccessSpy()
  respondActivityTaskCanceled: nodeLikeSuccessSpy()
  respondActivityTaskFailed: nodeLikeSuccessSpy()

module.exports = mockSWF

