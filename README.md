Balihoo Node.js Fulfillment Worker Library
==========================================

## Version
0.2.4

## Installation
Make sure you have a recent version of node and npm installed and then run:
    npm install balihoo-fulfillment-worker
  
## Usage
Simply instantiate a worker with configuration and a function to be called when work is available:
  
    var BalihooFulfillmentWorker = require(\'balihoo-fulfillment-worker\');
      
    var myWorkFunction = function (input) { 
        return input.x + input.y; 
    }
      
    var worker = new BalihooFulfillmentWorker(config);
    worker.workAsync(myWorkFunction);
    
Need to do some work asynchronously?  Simply return a promise (we use bluebird, but any A+ promise will do).

## Configuration
Configuration is supplied as an object which can contain the following:
  * region (required): The AWS region.  Balihoo will provide this value.
  * domain (required): The Simple WorkFlow domain.  Balihoo will provide this value.
  * name (required): A string containing the name of your worker
  * version (required): A string containing the version of your worker
