Promise = require 'bluebird'
pg = require 'pg'
os = require 'os'
using = Promise.using
Promise.promisifyAll pg

fulfillmentActorInsert = 'INSERT INTO actor
  (instance_id, name, version, domain, host, history, specification, status, type,
  started_on, last_update)
  VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)'

updateStatus = 'UPDATE actor SET status=$2, last_update=$3 WHERE instance_id=$1'

updateHistory = 'UPDATE actor SET history=$2, last_update=$3 WHERE instance_id=$1'

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
  constructor: (@dbConfig) ->
    @connectionString =
      "postgres://#{dbConfig.username}:#{dbConfig.password}@#{dbConfig.host}:#{dbConfig.port or 5432}/#{dbConfig.name}"

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
    resolutionHistory = JSON.stringify resolutionHistory
    
    using getClient(@connectionString), (client) ->
      client.queryAsync updateHistory, [
        instanceId,
        resolutionHistory,
        new Date().toISOString()
      ]
      .then (result) ->
        console.log "Update result is #{JSON.stringify result}"
      .catch (err) ->
        console.log err
