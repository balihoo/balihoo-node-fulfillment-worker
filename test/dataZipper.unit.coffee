assert = require 'assert'
dataZipper = require '../lib/dataZipper'

bigTestData = require './bigTestData.json'

smallResult = {
  stuff: 'things'
}

describe 'dataZipper unit tests', ->
  describe 'deliver() / receive()', ->
    context "when the supplied data is less than #{dataZipper.INLINE_ZIP_THRESHOLD} bytes", ->
      it 'returns the supplied data', ->
        dataZipper.deliver smallResult
        .then (result) ->
          assert.strictEqual result, smallResult
          
    context "when the supplied data is greater than #{dataZipper.INLINE_ZIP_THRESHOLD} bytes", ->
      it 'returns a compressed and base64-encoded string', ->
        expectedStart = dataZipper.ZIP_PREFIX + dataZipper.SEPARATOR
        
        dataZipper.deliver bigTestData
        .then (encodedResult) ->
          assert typeof encodedResult is 'string'
          assert encodedResult.slice(0, expectedStart.length) is expectedStart
          
          dataZipper.receive encodedResult
        .then (decodedResult) ->
          result = JSON.parse decodedResult
          assert.deepEqual result, bigTestData
