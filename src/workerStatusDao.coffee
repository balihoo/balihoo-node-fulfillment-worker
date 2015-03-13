Promise = require 'bluebird'
pg = require 'pg'
os = require 'os'
using = Promise.using
Promise.promisifyAll pg

fulfillmentActorInsert = 'INSERT INTO fulfillment_actor
  (instance_id, activity_name, version, domain, host_address, resolution_history, specification, status, type,
  started_on, last_update)
  VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)'

updateStatus = 'UPDATE fulfillment_actor SET status=$2, last_update=$3 WHERE instance_id=$1'

updateHistory = 'UPDATE fulfillment_actor SET resolution_history=$2, last_update=$3 WHERE instance_id=$1'

###
Get a self-disposing PgSQL client

Must be invoked via using(database.getClient()...);

@returns {Disposer.<client>} Disposer for a PgSQL client
###
getClient = getClient = (connectionString) ->
  close = undefined
  Promise.try ->
    pg.connectAsync connectionString
  .spread (client, done) ->
    close = done
    client
  .disposer ->
    close()

module.exports = class WorkerStatusDao
  constructor: (@config) ->
    @connectionString =
      "postgres://#{config.dataWarehouseUser}:#{config.dataWarehousePassword}@#{config.dataWarehouseHost}" +
      ":#{config.dataWarehousePort}/#{config.dataWarehouseDatabase}"

  createFulfillmentActor: (instanceId, name, version, domain, specification) ->
    now = new Date().toISOString()

    using getClient(@connectionString), (client) ->
      client.queryAsync fulfillmentActorInsert, [
        instanceId,
        name,
        version,
        domain,
        os.hostname(),
        JSON.stringify([]),
        JSON.stringify(specification),
        'starting',
        'w',
        now,
        now
      ]

  updateStatus: (instanceId, status) ->
    using getClient(@connectionString), (client) ->
      client.queryAsync updateStatus, [
        instanceId,
        status,
        new Date().toISOString()
      ]

  updateHistory: (instanceId, resolutionHistory) ->
    using getClient(@connectionString), (client) ->
      client.queryAsync updateHistory, [
        instanceId,
        JSON.stringify(resolutionHistory),
        new Date().toISOString()
      ]
