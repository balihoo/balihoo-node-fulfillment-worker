sinon = require 'sinon'

class mockSWF
  constructor: (@config) ->

  describeActivityType: sinon.spy ->
    return true

  registerActivityType: sinon.spy ->
    return true

  pollForActivityTask: sinon.spy ->
    return true

  respondActivityTaskCompleted: sinon.spy ->
    return true

  respondActivityTaskCanceled: sinon.spy ->
    return true

  respondActivityTaskFailed: sinon.spy ->
    return true

module.exports = mockSWF