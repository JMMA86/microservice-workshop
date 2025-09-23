'use strict';
const express = require('express')
const bodyParser = require("body-parser")
const jwt = require('express-jwt')

const ZIPKIN_URL = process.env.ZIPKIN_URL || 'http://127.0.0.1:9411/api/v2/spans';
const {Tracer, 
  BatchRecorder,
  jsonEncoder: {JSON_V2}} = require('zipkin');
  const CLSContext = require('zipkin-context-cls');  
const {HttpLogger} = require('zipkin-transport-http');
const zipkinMiddleware = require('zipkin-instrumentation-express').expressMiddleware;

const logChannel = process.env.REDIS_CHANNEL || 'log_channel';
const REDIS_ENABLED = process.env.REDIS_ENABLED !== 'false';

let redisClient = null;

if (REDIS_ENABLED) {
  redisClient = require("redis").createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_ZHK_PORT || 6379,
    retry_strategy: function (options) {
        if (options.error && options.error.code === 'ECONNREFUSED') {
            console.log('Redis connection refused, retrying in', Math.min(options.attempt * 100, 3000), 'ms');
            return Math.min(options.attempt * 100, 3000);
        }
        if (options.total_retry_time > 1000 * 60 * 10) {
            console.log('Redis retry time exhausted, giving up');
            return new Error('Redis retry time exhausted');
        }
        if (options.attempt > 20) {
            console.log('Max Redis connection attempts reached, giving up');
            return new Error('Max Redis connection attempts reached');
        }
        console.log('Attempting to connect to Redis, attempt #' + options.attempt);
        return Math.min(options.attempt * 100, 3000);
    }        
  });

  // Add Redis event listeners for better error handling
  redisClient.on('connect', function() {
      console.log('Redis client connected');
  });

  redisClient.on('ready', function() {
      console.log('Redis client ready');
  });

  redisClient.on('error', function(err) {
      console.log('Redis client error (service will continue):', err.message);
  });

  redisClient.on('end', function() {
      console.log('Redis client connection ended');
  });

  redisClient.on('reconnecting', function() {
      console.log('Redis client reconnecting...');
  });
} else {
  console.log('Redis disabled - logging operations will be skipped');
}
const port = process.env.TODO_API_PORT || 8082
const jwtSecret = process.env.JWT_SECRET || "myfancysecret"

const app = express()

const cors = require('cors');
app.use(cors());

const ctxImpl = new CLSContext('zipkin');
const recorder = new BatchRecorder({
  logger: new HttpLogger({
    endpoint: ZIPKIN_URL,
    jsonEncoder: JSON_V2,
    timeout: 5000,
    onError: (error) => {
      console.warn('Zipkin logging error (service will continue):', error.message);
    }
  })
});
const localServiceName = 'todos-api';
const tracer = new Tracer({ctxImpl, recorder, localServiceName});


app.use(jwt({ secret: jwtSecret }))
app.use(zipkinMiddleware({tracer}));
app.use(function (err, req, res, next) {
  if (err.name === 'UnauthorizedError') {
    res.status(401).send({ message: 'invalid token' })
  }
})
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

const routes = require('./routes')
routes(app, {tracer, redisClient, logChannel})

app.listen(port, '0.0.0.0', function () {
  console.log('todo list RESTful API server started on: ' + port)
})
