"use strict";
var assert = require("assert");

var FulfillmentWorker = require("../lib/fulfillmentWorker");
var error = require("../lib/error");
var config;

var testRequiresConfigParameter = function(config, propName) {
  delete(config[propName]);

  try {
    new FulfillmentWorker(config);
    assert.fail("Expected a ConfigurationMissingError.");
  } catch (err) {
    assert(err instanceof error.ConfigurationMissingError);
    assert.strictEqual(err.missingProperty, propName);
  }
};

describe("FulfillmentWorker unit tests", function() {
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
      try {
        new FulfillmentWorker();
        assert.fail("Expected a ConfigurationMustBeObjectError.");
      } catch(err) {
        assert(err instanceof error.ConfigurationMustBeObjectError);
        assert.strictEqual(err.suppliedType, "undefined");
      }
    });
    it("Requires that the config be an object", function() {
      try {
        new FulfillmentWorker("not an object");
        assert.fail("Expected a ConfigurationMustBeObjectError.");
      } catch(err) {
        assert(err instanceof error.ConfigurationMustBeObjectError);
        assert.strictEqual(err.suppliedType, "string");
      }
    });
    it("Requires config.region", function() {
      testRequiresConfigParameter(config, "region");
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