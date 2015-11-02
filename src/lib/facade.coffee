
require('es6-promise').polyfill()

Util = require '../util'

GeneralFactory = require './general-factory'
MasterDataResource = require '../master-data-resource'
ModelProps = require './model-props'

getProto = Object.getPrototypeOf ? (obj) -> obj.__proto__

###*
Facade class of DDD pattern.

- create instance of factories
- create instance of repositories

@class Facade
@implements RootInterface
@module base-domain
###
class Facade

    ###*
    is root (to identify RootInterface)
    @property {Boolean} isRoot
    @static
    ###
    @isRoot: true


    ###*
    Get facade

    @method getFacade
    @return {Facade}
    @chainable
    ###
    getFacade: -> @


    ###*
    create instance of Facade

    @method createInstance
    @static
    @param {Object} [options]
    @return {Facade}
    ###
    @createInstance: (options = {}) ->
        Constructor = @
        return new Constructor(options)


    ###*
    constructor

    @constructor
    @param {String} [options]
    @param {String} [options.dirname="."] path where domain definition files are included
    @param {Boolean} [options.master] if true, MasterDataResource is enabled.
    ###
    constructor: (options = {}) ->

        Object.defineProperties @,
            classes:
                value: {}

            modelProps:
                value: {}

        @dirname = options.dirname ? '.'

        if options.master

            ###*
            instance of MasterDataResource
            Exist only when "master" property is given to Facade's option

            @property {MasterDataResource} master
            @optional
            @readOnly
            ###
            @master = new MasterDataResource(@)

        @init()
        @master?.init()


    # for base-domainify. keep it empty
    init: ->


    ###*
    get a model class

    @method getModel
    @param {String} modelName
    @return {Function}
    ###
    getModel: (modelName) ->
        return @require(modelName)


    ###*
    create an instance of the given modelName using obj
    if obj is null or undefined, empty object will be created.

    @method createModel
    @param {String} modelName
    @param {Object} obj
    @param {Object} [options]
    @param {RootInterface} [root]
    @return {BaseModel}
    ###
    createModel: (modelName, obj, options, root) ->
        GeneralFactory.createModel(modelName, obj, options, root ? @)


    ###*
    create a factory instance
    2nd, 3rd, 4th ... arguments are the params to pass to the constructor of the factory

    @method createFactory
    @param {String} modelName
    @return {BaseFactory}
    ###
    createFactory: (modelName, params...) ->
        @__create(modelName, 'factory', params, @)


    ###*
    create a repository instance
    2nd, 3rd, 4th ... arguments are the params to pass to the constructor of the repository

    @method createRepository
    @param {String} modelName
    @return {BaseRepository}
    ###
    createRepository: (modelName, params...) ->
        @__create(modelName, 'repository', params, @)


    ###*
    create a service instance
    2nd, 3rd, 4th ... arguments are the params to pass to the constructor of the service

    @method createService
    @param {String} name
    @return {BaseService}
    ###
    createService: (name, params...) ->
        @__create(name, 'service', params, @)


    __create: (modelName, type, params, root) ->
        Class = ClassWithConstructor = @require("#{modelName}-#{type}")

        while ClassWithConstructor.length is 0 and ClassWithConstructor isnt Object
            ClassWithConstructor = getProto(ClassWithConstructor::).constructor

        while params.length < ClassWithConstructor.length - 1
            params.push undefined

        return new Class(params..., root ? @)



    ###*
    read a file and returns class

    @method require
    @private
    @param {String} name
    @return {Function}
    ###
    require: (name) ->
        return @classes[name] if @classes[name]?

        file = "#{@dirname}/#{name}"
        try
            klass = Util.requireFile file
        catch e
            throw @error('modelNotFound', "model '#{name}' is not found")

        @addClass name, klass


    ###*
    check existence of the class of the given name

    @method hasClass
    @param {String} name
    @return {Function}
    ###
    hasClass: (name) ->
        try
            @require(name)
            return true
        catch e
            return false


    ###*
    add class to facade.
    the class is acquired by @require(name)

    @method addClass
    @private
    @param {String} name
    @param {Function} klass
    @param {Boolean} skipNameValidation validate class name is compatible with the name to register
    @return {Function}
    ###
    addClass: (name, klass, skipNameValidation = false) ->

        klass.className = name

        @classes[name] = klass


    ###*
    Get ModelProps by modelName.
    ModelProps summarizes properties of this class

    @method getModelProps
    @param {String} modelName
    @return {ModelProps}
    ###
    getModelProps: (modelName) ->

        if not @modelProps[modelName]?

            Model = @getModel(modelName)

            @modelProps[modelName] = new ModelProps(modelName, Model.properties, @)

        return @modelProps[modelName]

    ###*
    create instance of DomainError

    @method error
    @param {String} reason reason of the error
    @param {String} [message]
    @return {Error}
    ###
    error: (reason, message) ->

        DomainError = @constructor.DomainError
        return new DomainError(reason, message)


    ###*
    check if given object is instance of DomainError

    @method isDomainError
    @param {Error} e
    @return {Boolean}
    ###
    isDomainError: (e) ->

        DomainError = @constructor.DomainError
        return e instanceof DomainError


    ###*
    insert fixture data
    (Node.js only)

    @method insertFixtures
    @param {Object} [options]
    @param {String} [options.dataDir='./data'] directory to have fixture data files
    @param {String} [options.tsvDir='./tsv'] directory to have TSV files
    @param {Array(String)} [options.models=null] model names to insert. default: all models
    @return {Promise(EntityPool)} inserted data
    ###
    insertFixtures: (options = {}) ->

        Fixture = require '../fixture'
        fixture = new Fixture(@, options)
        fixture.insert(options.models)


    @Base                : require './base'
    @BaseModel           : require './base-model'
    @BaseService         : require './base-service'
    @ValueObject         : require './value-object'
    @Entity              : require './entity'
    @AggregateRoot       : require './aggregate-root'
    @Collection          : require './collection'
    @BaseList            : require './base-list'
    @BaseDict            : require './base-dict'
    @BaseFactory         : require './base-factory'
    @BaseRepository      : require './base-repository'
    @BaseSyncRepository  : require './base-sync-repository'
    @BaseAsyncRepository : require './base-async-repository'
    @LocalRepository     : require './local-repository'
    @MasterRepository    : require './master-repository'
    @DomainError         : require './domain-error'
    @GeneralFactory      : require './general-factory'


module.exports = Facade
