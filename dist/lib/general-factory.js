'use strict';
var BaseDict, BaseList, GeneralFactory, Util,
  hasProp = {}.hasOwnProperty;

BaseList = require('./base-list');

BaseDict = require('./base-dict');

Util = require('../util');


/**
general factory class

create instance of model

@class GeneralFactory
@implements FactoryInterface
@module base-domain
 */

GeneralFactory = (function() {

  /**
  create a factory.
  If specific factory is defined, return the instance.
  Otherwise, return instance of GeneralFactory.
  This method is not suitable for creating collections, thus only called by Repository, which handles Entity (= non-collection).
  
  @method create
  @static
  @param {String} modelName
  @param {RootInterface} root
  @return {FactoryInterface}
   */
  GeneralFactory.create = function(modelName, root) {
    var e, error;
    try {
      return root.createPreferredFactory(modelName);
    } catch (error) {
      e = error;
      return new GeneralFactory(modelName, root);
    }
  };


  /**
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
   */

  GeneralFactory.createModel = function(modelName, obj, options, root) {
    var Model;
    if (obj === null) {
      return null;
    }
    Model = root.getModule().getModel(modelName);
    if (Model.prototype instanceof BaseList) {
      return this.create(Model.itemModelName, root).createList(modelName, obj, options);
    } else if (Model.prototype instanceof BaseDict) {
      return this.create(Model.itemModelName, root).createDict(modelName, obj, options);
    } else {
      return this.create(modelName, root).createFromObject(obj != null ? obj : {}, options);
    }
  };


  /**
  constructor
  
  @constructor
  @param {String} modelName
  @param {RootInterface} root
   */

  function GeneralFactory(modelName1, root1) {
    this.modelName = modelName1;
    this.root = root1;
    this.facade = this.root.facade;
    this.modelProps = this.facade.getModelProps(this.root.getModule().normalizeName(this.modelName));
  }


  /**
  get model class this factory handles
  
  @method getModelClass
  @return {Function}
   */

  GeneralFactory.prototype.getModelClass = function() {
    return this.root.getModule().getModel(this.modelName);
  };


  /**
  create empty model instance
  
  @method createEmpty
  @public
  @return {BaseModel}
   */

  GeneralFactory.prototype.createEmpty = function() {
    return this.createFromObject({});
  };


  /**
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
   */

  GeneralFactory.prototype.createFromObject = function(obj, options) {
    var ModelClass, defaultValue, i, len, model, prop, ref, subModelName, value;
    if (options == null) {
      options = {};
    }
    ModelClass = this.getModelClass();
    if (obj instanceof ModelClass) {
      return obj;
    }
    if ((obj == null) || typeof obj !== 'object') {
      return null;
    }
    model = this.create();
    for (prop in obj) {
      if (!hasProp.call(obj, prop)) continue;
      value = obj[prop];
      if ((value == null) && this.modelProps.isOptional(prop)) {
        continue;
      }
      if (subModelName = this.modelProps.getSubModelName(prop)) {
        value = this.constructor.createModel(subModelName, value, options, this.root);
      }
      model.set(prop, value);
    }
    ref = this.modelProps.getAllProps();
    for (i = 0, len = ref.length; i < len; i++) {
      prop = ref[i];
      if ((model[prop] != null) || obj.hasOwnProperty(prop)) {
        continue;
      }
      if (this.modelProps.isId(prop)) {
        continue;
      }
      if (this.modelProps.isOptional(prop)) {
        continue;
      }
      defaultValue = this.modelProps.getDefaultValue(prop);
      if (subModelName = this.modelProps.getSubModelName(prop)) {
        if (this.modelProps.isEntity(prop)) {
          continue;
        }
        model.set(prop, this.constructor.createModel(subModelName, defaultValue, options, this.root));
      } else if (defaultValue != null) {
        switch (typeof defaultValue) {
          case 'object':
            defaultValue = Util.clone(defaultValue);
            break;
          case 'function':
            defaultValue = defaultValue();
        }
        model.set(prop, defaultValue);
      } else {
        model.set(prop, void 0);
      }
    }
    if (options.include !== null) {
      this.include(model, options.include).then((function(_this) {
        return function(model) {
          if (model.constructor.isImmutable) {
            return model.freeze();
          } else {
            return model;
          }
        };
      })(this));
    } else if (model.constructor.isImmutable) {
      return model.freeze();
    }
    return model;
  };


  /**
  include submodels
  
  @method include
  @private
  @param {BaseModel} model
  @param {Object} [includeOptions]
  @param {Object} [includeOptions.async=false] include submodels asynchronously
  @param {Array(String)} [includeOptions.props] include submodels of given props
   */

  GeneralFactory.prototype.include = function(model, includeOptions) {
    if (includeOptions == null) {
      includeOptions = {};
    }
    if (includeOptions.async == null) {
      includeOptions.async = false;
    }
    if (!includeOptions) {
      return Promise.resolve(model);
    }
    return model.include(includeOptions);
  };


  /**
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
   */

  GeneralFactory.prototype.createList = function(listModelName, val, options) {
    return this.createCollection(listModelName, val, options);
  };


  /**
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
   */

  GeneralFactory.prototype.createDict = function(dictModelName, val, options) {
    return this.createCollection(dictModelName, val, options);
  };


  /**
  create collection
  
  @method createCollection
  @private
  @param {String} collModelName model name of collection
  @param {any} val
  @param {Object} [options]
  @return {BaseDict} dict
   */

  GeneralFactory.prototype.createCollection = function(collModelName, val, options) {
    if (val === null) {
      return null;
    }
    if (val == null) {
      val = [];
    }
    if (Array.isArray(val)) {
      if (typeof val[0] === 'object') {
        val = {
          items: val
        };
      } else {
        val = {
          ids: val
        };
      }
    }
    return new GeneralFactory(collModelName, this.root).createFromObject(val, options);
  };


  /**
  create an empty model
  
  @protected
  @return {BaseModel}
   */

  GeneralFactory.prototype.create = function() {
    var Model;
    Model = this.getModelClass();
    return new Model(null, this.root);
  };

  return GeneralFactory;

})();

module.exports = GeneralFactory;