define [
  'underscore'
  'jquery'
  'backbone'
], (_, $, Backbone, lifecycleEvents) ->
  # This class provides a reliable application lifecycle eventing system. In an event-based
  # system the listener has to bind before the event is triggered. In a promise-based
  # system the promise needs to be created before its requested.  This class solves
  # both cases by allowing clients to wait for a event that may have already occurred
  # or will occur at some time in the future, even before the event promise has been
  # created.  It then allows clients that fulfill the event promise to bind their promise
  # or data to an event at any time.
  #
  # Usage:
  #   When binding events you can pass unresolved promises, resolved promises, objects or no data at all
  #     lifecycle.bind 'event-a', $.Deferred().promise
  #     lifecycle.bind 'event-b', $.Deferred().resolve({}).promise()
  #     lifecycle.bind 'event-c', {}
  #     lifecycle.bind 'event-d'
  #
  #   When listening to events you can listen to a single or multiple events
  #     lifecycle.when('event-a').then ->
  #     lifecycle.when('event-b', 'event-c', 'event-d').then (b, c) ->
  class Lifecycle
    _init: ->
      @promises = {}
      @events = _.extend {}, Backbone.Events

    # Resets the tracked promises. Editors will have to rebind their lifecycle events after this is called.
    reset: ->
      @promises = {}

    # Binds a promise or anything whenable to a named event.  Used by lifecycle event
    # generators to trigger promise-based events that consumers may wait on at any time.
    #
    # @param [String] name The name of the event
    # @param [Promise] whenable A promise or any whenable
    bind: (name, whenable) ->
      promise = $.when(whenable).promise()
      @promises[name] = promise
      @events.trigger name, promise unless @suppressLifecycleEvents

    # Resolves when the supplied list of lifecycle events have resolved.  Can be called at
    # any time.
    #
    # @param [String] events Any number of event names as separate parameters
    # @return [Promise] A promise that will resolve when all supplied events have resolved
    when: (events) ->
      promises = _(arguments).map (name) =>
        if @promises[name]?
          return @promises[name]
        # The promise hasn't been bound so listen for it
        else
          deferred = $.Deferred()
          @events.once name, (promise) ->
            promise.done deferred.resolve
          return deferred.promise()

      $.when.apply this, promises

    constructor: ->
      @suppressLifecycleEvents = Galileo.suppressLifecycleEvents # testing hook
      @_init()

  new Lifecycle()
