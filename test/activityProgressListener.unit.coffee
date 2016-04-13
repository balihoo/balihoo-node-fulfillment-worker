assert = require 'assert'
sinon = require 'sinon'
ActivityProgressListener = require '../lib/activityProgressListener'
Promise = require 'bluebird'

describe 'ActivityProgressListener unit tests', ->

  describe '_write', ->
    it 'should emit appropriate number of heartbeat requests', ->
      count = 0
      hbFunc = -> Promise.try -> count++
      listener = new ActivityProgressListener 0.1, hbFunc
      write = -> listener._write null, null, ->
      Promise
        .delay 125
        .then write # heartbeat should be sent here
        .delay 10
        .then write
        .delay 115 # heartbeat should be sent here
        .then write
        .delay 10
        .then -> assert.equal 2, count

    it 'should emit error event if hearbeat promise yields error', ->
      errored = false
      hbFunc = -> Promise.reject new Error 'test error'
      listener = new ActivityProgressListener 0.1, hbFunc
      write = -> listener._write null, null, ->
      listener.on 'error', -> errored = true
      Promise
        .delay 125
        .then write # heartbeat should be sent here
        .delay 20
        .then -> assert errored, 'ActivityProgressListener should have emitted error event!'

  describe 'handler', ->
    it 'should emit appropriate number of heartbeat requests', ->
      count = 0
      hbFunc = -> Promise.try -> count++
      listener = new ActivityProgressListener 0.1, hbFunc
      handle = -> listener.handler()
      Promise
        .delay 125
        .then handle # heartbeat should be sent here
        .delay 10
        .then handle
        .delay 115 # heartbeat should be sent here
        .then handle
        .delay 10
        .then -> assert.equal 2, count
