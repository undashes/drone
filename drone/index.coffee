_               = require 'lodash'
arDrone         = require 'ar-drone'
{EventEmitter}  = require 'events'
opencv          = require 'opencv'

enable_opencv = false

class Drone extends EventEmitter
    constructor: (@log) ->
        @arClient  = arDrone.createClient()
        @pngStream = @arClient.getPngStream()
        @pngStream.on 'data', (data) =>
            @processMatrix data, (error, faces) =>
                if error
                    @log.error error
                    return
                @emit 'frame', data, faces

    processMatrix: (data, callback) ->
        return callback(null, {}) unless opencv? and enable_opencv
        opencv.readImage data, (error, mat) ->
            return callback(new Error('error reading image:' + error.message)) if error
            mat.detectObject opencv.FACE_CASCADE, {}, (error, faces) ->
                return callback(new Error('error processing image:' + error.message)) if error
                callback null, faces

    takeoff: ->
        @log.info 'taking off...'
        @arClient.takeoff ->
            @log.notice 'drone took off'
            @arClient.stop()

    land: ->
        @log.info 'landing...'
        @arClient.stop()
        @arClient.land ->
            @log.notice 'drone landed'


module.exports = (log) ->
    new Drone(log)
