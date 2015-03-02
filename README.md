Balihoo Node.js Fulfillment Worker Library
==========================================

## Version
0.2.13

## Installation
Make sure you have a recent version of node and npm installed and then run:
    
    npm install balihoo-fulfillment-worker
  
## Usage
Simply instantiate a worker with configuration and a function to be called when work is available:
  
    var BalihooFulfillmentWorker = require('balihoo-fulfillment-worker');
      
    var myWorkFunction = function (input) { 
        return input.x + input.y; 
    }
      
    var worker = new BalihooFulfillmentWorker(config);
    worker.workAsync(myWorkFunction);
    
    process.on('SIGINT', function() {
        worker.stop();
    });
    
    process.on('SIGTERM', function() {
        worker.stop();
    });
    
Need to do some work asynchronously?  Simply return a promise (we use bluebird, but any A+ promise will do).

## Configuration
Configuration is supplied as an object which must contain the following:
  * region: The AWS region.  Balihoo will provide this value.
  * domain: The Simple WorkFlow domain.  Balihoo will provide this value.
  * name: A string containing the name of your worker
  * version: A string containing the version of your worker

You may optionally specify a schema for input and output:
  * parameterSchema: An object representing a [JSON schema](http://json-schema.org/) that the task must match before being passed to your worker
  * resultSchema: An object representing a [JSON schema](http://json-schema.org/) that will be used to validate the result from your worker

You may also specify your AWS credentials, though we recommend you use the methods described by Amazon [here](http://docs.aws.amazon.com/AWSJavaScriptSDK/guide/node-configuring.html):
  * accessKeyId: A string containing your AWS access key ID
  * secretAccessKey: A string containing your AWS secret access key
   
Additionally, some optional parameters which control the default timeouts for this worker can be specified.  Note that these values will only be used if the task creator does not specify values.
  * defaultTaskHeartbeatTimeout: The default maximum time before the worker must report progress
  * defaultTaskScheduleToCloseTimeout: The default maximum duration for a task
  * defaultTaskScheduleToStartTimeout: The default maximum duration that a task can wait before being assigned to a worker
  * defaultTaskStartToCloseTimeout: The default maximum duration that the worker can take to process a task
