var Promise, WorkerStatusDao, debounce, fulfillmentActorInsert, getClient, os, pg, updateStatus, using;

Promise = require('bluebird');

pg = require('pg');

os = require('os');

debounce = require('debounce');

using = Promise.using;

Promise.promisifyAll(pg);

fulfillmentActorInsert = 'INSERT INTO actor (instance_id, name, version, domain, host, history, specification, status, type, started_on, last_update) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)';

updateStatus = 'UPDATE actor SET status=$2, history=$3, last_update=$4 WHERE instance_id=$1';


/*
  Get a self-disposing PgSQL client

  Must be invoked via using(database.getClient()...);

  @returns {Disposer.<client>} Disposer for a PgSQL client
 */

getClient = getClient = function(connectionString) {
  var close;
  close = void 0;
  return Promise["try"](function() {
    return pg.connectAsync(connectionString);
  }).spread(function(client, done) {
    close = done;
    return client;
  }).disposer(function() {
    return close();
  });
};

module.exports = WorkerStatusDao = (function() {
  function WorkerStatusDao(dbConfig1) {
    this.dbConfig = dbConfig1;
    this.connectionString = "postgres://" + dbConfig.username + ":" + dbConfig.password + "@" + dbConfig.host + ":" + (dbConfig.port || 5432) + "/" + dbConfig.name;
    this.updateStatus = debounce((function(_this) {
      return function(instanceId, status, resolutionHistory) {
        return using(getClient(_this.connectionString), function(client) {
          return client.queryAsync(updateStatus, [instanceId, status, resolutionHistory, new Date().toISOString()]);
        });
      };
    })(this), 10000, true);
  }

  WorkerStatusDao.prototype.createFulfillmentActor = function(instanceId, name, version, domain, specification) {
    var now;
    now = new Date().toISOString();
    return using(getClient(this.connectionString), function(client) {
      return client.queryAsync(fulfillmentActorInsert, [instanceId, name, version, domain, os.hostname(), JSON.stringify([]), JSON.stringify(specification), 'Starting..', 'w', now, now]);
    });
  };

  return WorkerStatusDao;

})();
