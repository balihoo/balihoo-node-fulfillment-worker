sinon = require 'sinon'

mockFunc = ->
  return sinon.spy (item, callback) ->
    callback null, true

class mockSWF
  constructor: (@config) ->

  describeActivityType: mockFunc()
  registerActivityType: mockFunc()
  pollForActivityTask: mockFunc()
  respondActivityTaskCompleted: mockFunc()
  respondActivityTaskCanceled: mockFunc()
  respondActivityTaskFailed: mockFunc()

module.exports = mockSWF