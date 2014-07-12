#!/usr/local/bin coffee
Master = require './master'

class Dispatcher

  constructor: ->
    return new Master

exports = module.exports = Dispatcher
