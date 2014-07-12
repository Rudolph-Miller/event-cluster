Dispatcher for Node.js
===

Author: Rudolph-Miller
---
***

1. How to use
	```
	cluster = new require './event-cluster'
	cluster.use *id*, *function*

	if cluster.isMaster
		cluster.fork()
		cluster.pushQ *id*, *target*
		cluster.on 'result', (message) -> message.result = *function*( *target* )
	```

2. Master
	1. Properties
		* isMaster -> if dispathcer is master return true else false.
		* isWorker -> if dispathcer is worker return true else false.
		* pid -> return pid of instance.
	2. Methods
		* fork() -> make instance of worker.
		* forks(n) -> make n instances of worker.
		* use(*id*, *function*) -> register *id* and *function* (typeof *id* is 'string').
		* pushQ(*id*, *target*) -> push *id* and *target* on Queue.
		* remove() -> exit all workers which is working.
	3. Events
		* on 'pullTask',(message) -> message.pid is the pid of worker which pull task.
		* on 'result', (message) -> message.result is result of task, message.task is task.
		* on 'workerStart', (message) -> message.pid is the pid of starting worker.

3. Worker
	You can not customize Worker or touch on them, because Workers are precious for them and do not push everythig against them.
