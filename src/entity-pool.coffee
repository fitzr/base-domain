'use strict'

###*
@class EntityPool
@module base-domain
###
class EntityPool

    constructor: ->

    ###*
    Register an entity to pool
    @method set
    @param {Entity} model
    ###
    set: (model) ->

        Model = model.constructor
        return if not Model.isEntity or not model?.id?

        modelName = Model.getName()

        throw new Error("invalid model name #{modelName}") if EntityPool::[modelName]

        @[modelName] ?= {}
        @[modelName][model.id] = model


    ###*
    Get registred models by model name and id

    @method get
    @param {String} modelName
    @param {String} id
    @return {Entity}
    ###
    get: (modelName, id) ->

        @[modelName]?[id]


    ###*
    Clear all the registered entities

    @method clear
    ###
    clear: ->
        for modelName, models of @
            for id of models
                delete models[id]
            delete models[modelName]

module.exports = EntityPool
