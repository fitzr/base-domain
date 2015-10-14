
###*
interface of Aggregate Root

@class RootInterface
@module base-domain
###
class RootInterface

   # this file is just a concept and no implementation here.

    ###*
    is root (to identify RootInterface)
    @property {Boolean} isRoot
    @static
    ###

    ###*
    key: modelName, value: MemoryResource

    @property {Object(MemoryResource)} memories
    ###

    ###*
    create a factory instance

    @method createFactory
    @param {String} modelName
    @return {BaseFactory}
    ###

    ###*
    create a repository instance

    @method createRepository
    @param {String} modelName
    @return {BaseRepository}
    ###

    ###*
    create a service instance
    2nd, 3rd, 4th ... arguments are the params to pass to the constructor of the service

    @method createService
    @param {String} name
    @return {BaseRepository}
    ###

    ###*
    get a model class

    @method getModel
    @param {String} modelName
    @return {Function}
    ###
    ###*
    create an instance of the given modelName using obj
    if obj is null or undefined, empty object will be created.

    @method createModel
    @param {String} modelName
    @param {Object} obj
    @param {Object} [options]
    @return {BaseModel}
    ###

    ###*
    get or create a memory resource to save to @memories

    @method useMemoryResource
    @param {String} modelName
    @return {MemoryResource}
    ###

module.exports = RootInterface
