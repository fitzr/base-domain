'use strict'

BaseList = require './base-list'
BaseDict = require './base-dict'
Util = require '../util'

###*
general factory class

create instance of model

@class GeneralFactory
@implements FactoryInterface
@module base-domain
###
class GeneralFactory

    ###*
    create a factory.
    If specific factory is defined, return the instance.
    Otherwise, return instance of GeneralFactory.
    This method is not suitable for creating collections, thus only called by Repository, which handles Entity (= non-collection).

    @method create
    @static
    @param {String} modelName
    @param {RootInterface} root
    @return {FactoryInterface}
    ###
    @create: (modelName, root) ->

        try
            return root.createPreferredFactory(modelName) # TODO: enable to pass 2nd arguement (noParent: boolean)

        catch e
            return new GeneralFactory(modelName, root)


    ###*
    create an instance of the given modelName using obj
    if obj is null, return null
    if obj is undefined, empty object is created.

    @method createModel
    @param {String} modelName
    @param {Object} obj
    @param {Object} [options]
    @param {Object} [options.include] options to pass to Includer
    @param {Object} [options.include.async=false] include sub-entities asynchronously if true.
    @param {Array(String)} [options.include.props] include sub-entities of given props
    @param {RootInterface} root
    @return {BaseModel}
    ###
    @createModel: (modelName, obj, options, root) ->

        return null if obj is null

        Model = root.getModule().getModel(modelName)

        if (Model::) instanceof BaseList
            return @create(Model.itemModelName, root).createList(modelName, obj, options)

        else if (Model::) instanceof BaseDict
            return @create(Model.itemModelName, root).createDict(modelName, obj, options)

        else
            return @create(modelName, root).createFromObject(obj ? {}, options)


    ###*
    constructor

    @constructor
    @param {String} modelName
    @param {RootInterface} root
    ###
    constructor: (@modelName, @root) ->
        @facade = @root.facade
        @modelProps = @facade.getModelProps(@root.getModule().normalizeName @modelName)


    ###*
    get model class this factory handles

    @method getModelClass
    @return {Function}
    ###
    getModelClass: ->
        @root.getModule().getModel(@modelName)


    ###*
    create empty model instance

    @method createEmpty
    @public
    @return {BaseModel}
    ###
    createEmpty: -> @createFromObject({})

    ###*
    create instance of model class by plain object

    for each prop, values are set by Model#set(prop, value)

    @method createFromObject
    @public
    @param {Object} obj
    @param {Object} [options={}]
    @param {Object} [options.include] options to pass to Includer
    @param {Object} [options.include.async=false] include sub-entities asynchronously if true.
    @param {Array(String)} [options.include.props] include sub-entities of given props
    @return {BaseModel} model
    ###
    createFromObject: (obj, options = {}) ->

        ModelClass = @getModelClass()

        return obj if obj instanceof ModelClass

        if not obj? or typeof obj isnt 'object'
            return null

        model = @create()

        # setting values to the model
        for own prop, value of obj

            continue if not value? and @modelProps.isOptional(prop)

            if subModelName = @modelProps.getSubModelName(prop)
                value = @constructor.createModel(subModelName, value, options, @root)

            model.set(prop, value)


        # adding empty values to the model
        for prop in @modelProps.getAllProps()

            continue if model[prop]? or obj.hasOwnProperty prop

            continue if @modelProps.isId(prop)
            continue if @modelProps.isOptional(prop)

            defaultValue = @modelProps.getDefaultValue(prop)

            if subModelName = @modelProps.getSubModelName(prop)
                continue if @modelProps.isEntity(prop) # entity will be loaded at include() section

                model.set(prop, @constructor.createModel(subModelName, defaultValue, options, @root))

            else if defaultValue?
                switch typeof defaultValue
                    when 'object'
                        defaultValue = Util.clone(defaultValue)
                    when 'function'
                        defaultValue = defaultValue()

                model.set(prop, defaultValue)

            else
                model.set(prop, undefined)

        # loading entities by id
        if options.include isnt null # skip @include when null is set. By default it's undefined, so @include will be executed
            @include(model, options.include).then (model) =>
                if model.constructor.isImmutable
                    return model.freeze()
                else
                    return model

        # immutability
        else if model.constructor.isImmutable
            return model.freeze()

        return model


    ###*
    include submodels

    @method include
    @private
    @param {BaseModel} model
    @param {Object} [includeOptions]
    @param {Object} [includeOptions.async=false] include submodels asynchronously
    @param {Array(String)} [includeOptions.props] include submodels of given props
    ###
    include: (model, includeOptions = {}) ->

        includeOptions.async ?= false

        return Promise.resolve(model) if not includeOptions

        return model.include includeOptions


    ###*
    create model list

    @method createList
    @public
    @param {String} listModelName model name of list
    @param {any} val
    @param {Object} [options]
    @param {Object} [options.include] options to pass to Includer
    @param {Object} [options.include.async=false] include sub-entities asynchronously if true.
    @param {Array(String)} [options.include.props] include sub-entities of given props
    @return {BaseList} list
    ###
    createList: (listModelName, val, options) -> @createCollection listModelName, val, options


    ###*
    create model dict

    @method createDict
    @public
    @param {String} dictModelName model name of dict
    @param {any} val
    @param {Object} [options]
    @param {Object} [options.include] options to pass to Includer
    @param {Object} [options.include.async=false] include sub-entities asynchronously if true.
    @param {Array(String)} [options.include.props] include sub-entities of given props
    @return {BaseDict} dict
    ###
    createDict: (dictModelName, val, options) -> @createCollection dictModelName, val, options


    ###*
    create collection

    @method createCollection
    @private
    @param {String} collModelName model name of collection
    @param {any} val
    @param {Object} [options]
    @return {BaseDict} dict
    ###
    createCollection: (collModelName, val, options) ->

        return null if val is null

        val ?= []

        if Array.isArray val
            if typeof val[0] is 'object'
                val = items: val
            else
                val = ids: val

        new GeneralFactory(collModelName, @root).createFromObject val, options


    ###*
    create an empty model

    @protected
    @return {BaseModel}
    ###
    create: ->
        Model = @getModelClass()
        return new Model(null, @root)


module.exports = GeneralFactory
