"use strict";
var assert = require("assert");

var NodeFulfillmentWorker = require("../lib/nodeFulfillmentWorker");
var error = require("../lib/error");
var config;

var testRequiresConfigParameter = function(config, propName) {
  var expectedError = "ConfigurationMissingError";

  delete(config[propName]);

  try {
    new NodeFulfillmentWorker(config);
    assert.fail("Expected a " + expectedError + ".");
  } catch (err) {
    assert.strictEqual(err.name, expectedError);
    assert.strictEqual(err.missingProperty, propName);
  }
};

describe("NodeFulfillmentWorker unit tests", function() {
  beforeEach(function() {
    config = {
      region: "fakeRegion",
      accessKeyId: "fakeAccessKeyId",
      secretAccessKey: "fakeSecretAccessKey",
      domain: "fakeDomain",
      name: "fakeWorkerName",
      version: "fakeWorkerVersion"
    };
  });
  describe("constructor", function() {
    it("Requires a config", function() {
      var expectedError = "ConfigurationMustBeObjectError";
      try {
        new NodeFulfillmentWorker();
        assert.fail("Expected a " + expectedError + ".");
      } catch(err) {
        assert.strictEqual(err.name, expectedError);
        assert.strictEqual(err.suppliedType, "undefined");
      }
    });
    it("Requires that the config be an object", function() {
      var expectedError = "ConfigurationMustBeObjectError";
      try {
        new NodeFulfillmentWorker("not an object");
        assert.fail("Expected a " + expectedError + ".");
      } catch(err) {
        assert.strictEqual(err.name, expectedError);
        assert.strictEqual(err.suppliedType, "string");
      }
    });
    it("Requires config.region", function() {
      testRequiresConfigParameter(config, "region");
    });
    it("Requires config.accessKeyId", function() {
      testRequiresConfigParameter(config, "accessKeyId");
    });
    it("Requires config.secretAccessKey", function() {
      testRequiresConfigParameter(config, "secretAccessKey");
    });
    it("Requires config.domain", function() {
      testRequiresConfigParameter(config, "domain");
    });
    it("Requires config.workerName", function() {
      testRequiresConfigParameter(config, "name");
    });
    it("Requires config.workerVersion", function() {
      testRequiresConfigParameter(config, "version");
    });
  });
});