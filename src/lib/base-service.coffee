'use strict'

Base = require './base'

###*
Base service class of DDD pattern.

the parent "Base" class just simply gives `this.facade` property

@class BaseService
@extends Base
@module base-domain
###
class BaseService extends Base

    constructor: (params..., root) ->
        super(root)

module.exports = BaseService
