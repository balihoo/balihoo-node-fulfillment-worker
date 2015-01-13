sinon = require 'sinon'

nodeLikeSuccessSpy = ->
  return sinon.spy (item, callback) ->
    callback null, true

class mockSWF
  constructor: (@config) ->

  describeActivityType: nodeLikeSuccessSpy()
  registerActivityType: nodeLikeSuccessSpy()
  pollForActivityTask: nodeLikeSuccessSpy()
  respondActivityTaskCompleted: nodeLikeSuccessSpy()
  respondActivityTaskCanceled: nodeLikeSuccessSpy()
  respondActivityTaskFailed: nodeLikeSuccessSpy()

module.exports = mockSWF

