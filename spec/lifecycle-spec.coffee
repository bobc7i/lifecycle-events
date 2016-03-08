define [
  'jquery'
  '../js/lifecycle'
], ($, lifecycle) ->
  describe 'Application Lifecycle', ->
    beforeEach ->
      @EVENT_A = 'event-a'
      @EVENT_B = 'event-b'
      lifecycle.suppressLifecycleEvents = false
      lifecycle._init()

    afterEach ->
      lifecycle.suppressLifecycleEvents = true
      lifecycle._init()

    it 'should be a Singleton', ->
      expect(lifecycle).toBeDefined()

    describe 'when an event promise is bound', ->
      beforeEach ->
        spyOn lifecycle.events, 'trigger'
        @deferredEventA = $.Deferred()
        lifecycle.bind @EVENT_A, @deferredEventA.promise()

      it 'should bind the event', ->
        expect(lifecycle.promises[@EVENT_A]).toEqual @deferredEventA.promise()

      it 'should trigger the event', ->
        expect(lifecycle.events.trigger).toHaveBeenCalledWith @EVENT_A, @deferredEventA.promise()

      describe 'and the event promise is listened to', ->
        beforeEach ->
          @whenEventA = lifecycle.when @EVENT_A

        it 'should return a promise', ->
          expect(@whenEventA.state()).toEqual 'pending'

        describe 'and the event promise is resolved', ->
          beforeEach ->
            @deferredEventA.resolve()

          it 'should notify the event promise listener', (done) ->
            @whenEventA.done ->
              done()

    describe 'when a resolved event is bound', ->
      beforeEach ->
        @deferredEventA = $.Deferred().resolve()
        lifecycle.bind @EVENT_A, @deferredEventA.promise()

      describe 'and the event promise is listened to', ->
        beforeEach ->
          @whenEventA = lifecycle.when @EVENT_A

        it 'should return a promise', ->
          expect(@whenEventA.state()).toEqual 'resolved'

        it 'should notify the event promise listener', (done) ->
          @whenEventA.done ->
            done()

    describe 'when a non-deferred event is bound', ->
      beforeEach ->
        lifecycle.bind @EVENT_A, a: 1

      describe 'and the event promise is listened to', ->
        beforeEach ->
          @whenEventA = lifecycle.when @EVENT_A

        it 'should return a promise', ->
          expect(@whenEventA.state()).toEqual 'resolved'

        it 'should notify the event promise listener', (done) ->
          @whenEventA.done (data) ->
            expect(data).toEqual a: 1
            done()

    describe 'when multiple events are bound', ->
      beforeEach ->
        spyOn lifecycle.events, 'trigger'
        @deferredEventA = $.Deferred()
        @deferredEventB = $.Deferred()
        lifecycle.bind @EVENT_A, @deferredEventA.promise()
        lifecycle.bind @EVENT_B, @deferredEventB.promise()

      it 'should bind the event', ->
        expect(lifecycle.promises[@EVENT_A]).toEqual @deferredEventA.promise()
        expect(lifecycle.promises[@EVENT_B]).toEqual @deferredEventB.promise()

      it 'should trigger the event', ->
        expect(lifecycle.events.trigger).toHaveBeenCalledWith @EVENT_A, @deferredEventA.promise()
        expect(lifecycle.events.trigger).toHaveBeenCalledWith @EVENT_B, @deferredEventB.promise()

      describe 'and all event promises are listened to', ->
        beforeEach ->
          @whenAllReady = lifecycle.when @EVENT_A, @EVENT_B

        it 'should return a promise', ->
          expect(@whenAllReady.state()).toEqual 'pending'

        describe 'and all the event promises are resolved', ->
          beforeEach ->
            @deferredEventA.resolve a: 1
            @deferredEventB.resolve b: 1

          it 'should notify the event promise listener', (done) ->
            @whenAllReady.then (a, b) ->
              expect(a).toEqual a: 1
              expect(b).toEqual b: 1
              done()

    describe 'when an event promise is listened to', ->
      beforeEach ->
        @whenEventA = lifecycle.when @EVENT_A

      it 'should return a promise', ->
        expect(@whenEventA.state()).toEqual 'pending'

      describe 'and the event promise is bound', ->
        beforeEach ->
          @deferredEventA = $.Deferred()
          lifecycle.bind @EVENT_A, @deferredEventA.promise()

        it 'should notify the event promise listener', (done) ->
          @whenEventA.done (a) ->
            expect(a).toEqual a: 1
            done()
          @deferredEventA.resolve a: 1

      describe 'and the resolved event promise is bound', ->
        beforeEach ->
          @deferredEventA = $.Deferred().resolve a: 1
          lifecycle.bind @EVENT_A, @deferredEventA.promise()

        it 'should notify the event promise listener', (done) ->
          @whenEventA.done (a) ->
            expect(a).toEqual a: 1
            done()

      describe 'and the non-deferred event is bound', ->
        beforeEach ->
          lifecycle.bind @EVENT_A, a: 1

        it 'should notify the event promise listener', (done) ->
          @whenEventA.done (a) ->
            expect(a).toEqual a: 1
            done()

      describe 'and the event is bound with no promise', ->
        beforeEach ->
          lifecycle.bind @EVENT_A

        it 'should notify the event promise listener', (done) ->
          @whenEventA.done ->
            done()

    describe 'when reset is called', ->
      it 'should remove all the tracked promises', ->
        lifecycle.bind 'foo', true
        lifecycle.bind 'bar', false
        expect(Object.keys(lifecycle.promises).length).toBe 2
        lifecycle.reset()
        expect(Object.keys(lifecycle.promises).length).toBe 0
