'use strict';
const TodoController = require('./todoController');
module.exports = function (app, {tracer, redisClient, logChannel}) {
  const todoController = new TodoController({tracer, redisClient, logChannel});
  app.route('/todos-api/health')
    .get(function(req,resp) { resp.status(200).send('OK'); });
  app.route('/todos-api/todos')
    .get(function(req,resp) {return todoController.list(req,resp)})
    .post(function(req,resp) {return todoController.create(req,resp)});

  app.route('/todos-api/todos/:taskId')
    .delete(function(req,resp) {return todoController.delete(req,resp)});
};