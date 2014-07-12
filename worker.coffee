#!/usr/local/bin coffee
cp = require 'child_process'

class Worker

  constructor: (master) ->
    @master = master if master
    @functions = @master.functions
    @pid = process.pid

  start: ->
    process.send {type: 'message', message: "Worker starts at #{@pid}"}
    process.once 'message', (message) =>
      if message.type is 'register' and message.pid is @pid
        @working()
      else
        process.send {type: 'error', errorType: 'registerFailed'}
        process.exit(0)

  working: ->
    process.on 'message', (message) =>
      @handleMasterMessage message
    process.send {type: 'pullTask', pid: @pid}

  handleMasterMessage: (message) ->
    switch message.type
      when 'deal'
        @deal message.task
      when 'exit'
        process.send {type: 'exit', pid: @pid}
        process.exit(0)

  deal: (task) ->
    try
      result = @functions[task.id] task.target
      process.send {type: 'result', result: result, task: task}
    catch error
      process.send {type: 'error', task: task, result: error}

  fork: (id) ->
    @proc = cp.fork(@master.cmd)

exports = module.exports = Worker
