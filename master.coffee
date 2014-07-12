#!/usr/local/bin coffee
cp = require 'child_process'
Worker = require './worker'
events = require 'events'

class Master extends events.EventEmitter

  constructor: () ->
    @isWorker = if process.env.EVENT_CLUSTER_MASTER_PID then true else false
    @isMaster = not @isWorker

    @functions = {}
    @workers = {}
    @listeningWorkers = []
    @pid = process.pid
    @queue = []
    @cmd = process.argv.slice(1)
    if @isMaster
      process.env.EVENT_CLUSTER_MASTER_PID = @pid
      console.log "Master starts at #{@pid}"
    if @isWorker
      worker = new Worker(this)
      worker.start()

  forks: (n=1) ->
    for i in [1..n]
      @fork()

  fork: ->
    worker = new Worker(this)
    worker.fork()
    @register worker

  use: (id, fn) ->
    @functions[id] = fn

  pushQ: (id, target) ->
    @queue.push {id: id, target: target}
    @tasker()

  sendMessage: (pid, message) ->
    worker = @workers[pid]
    worker.proc.send message

  register: (worker) ->
    pid = worker.proc.pid
    @workers[pid] = worker
    worker.proc.on 'message', (message) =>
      @handleWorkerMessage message
    @sendMessage pid, {type: 'register', pid: pid}

  handleWorkerMessage: (message) ->
    switch message.type
      when 'pullTask'
        @pullTask(message.pid)
        @emit 'pullTask', {pid: message.pid}
      when 'result'
        @emit 'result', {result: message.result, task: messagetask}
      when 'message'
        console.log message.message
      when 'working'
        @emit 'workerStart', {pid: message.pid}
      when 'exit'
        console.log "worker: #{message.pid} shutdown!"
      when 'error'
        console.log message.errorType
        switch message.errorType
          when 'registerFailed'
            @fork()
            console.log 'worker restart'
          when 'dealFailed'
            @pullTask message.task.id, message.task.target
            console.log 'repush task'

  pullTask: (pid) ->
    if pid
      @listeningWorkers.push pid
      @tasker()

  tasker: ->
    if @listeningWorkers.length > 0
      if @queue.length > 0
        task = @queue.shift()
        pid = @listeningWorkers.shift()
        @deal task, pid
        if @queue.length > 0
          @tasker()

  deal: (task, pid) ->
    console.log "worker: #{pid} deal with task: #{task.id}"
    @sendMessage pid, {type: 'deal', task: task}
    fn = @functions[task.id]
    fn task.target
    @pullTask pid

  remove: ->
    for i in @workers
      @sendMessage i {type: 'exit'}
    console.log 'All of workers has exited!'

exports = module.exports = Master
