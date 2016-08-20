'use strict';
var BaseSyncRepository, MasterRepository,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

BaseSyncRepository = require('./base-sync-repository');


/**
Master repository: handling static data
Master data are loaded from master-data directory (by default, it's facade.dirname + /master-data)
These data should be formatted in Fixture.
Master data are read-only, so 'save', 'update' and 'delete' methods are not available.
(And currently, 'query' and 'singleQuery' are also unavailable as MemoryResource does not support them yet...)

@class MasterRepository
@extends BaseSyncRepository
@module base-domain
 */

MasterRepository = (function(superClass) {
  extend(MasterRepository, superClass);


  /**
  Name of the data in master data.
  @modelName is used if not set.
  
  @property {String} dataName
  @static
   */

  MasterRepository.dataName = null;

  function MasterRepository() {
    var dataName, master, ref;
    MasterRepository.__super__.constructor.apply(this, arguments);
    master = this.facade.master;
    if (master == null) {
      throw this.error('masterNotFound', "MasterRepository is disabled by default.\nTo enable it, set the option to Facade.createInstance() like\n\nFacade.createInstance(master: true)");
    }
    dataName = (ref = this.constructor.dataName) != null ? ref : this.constructor.modelName;
    this.client = master.getMemoryResource(dataName);
  }


  /**
  Update or insert a model instance
  Save data with "fixtureInsertion" option. Otherwise throw an error.
  
  @method save
  @public
   */

  MasterRepository.prototype.save = function(data, options) {
    if (options == null) {
      options = {};
    }
    if (options.fixtureInsertion) {
      return MasterRepository.__super__.save.call(this, data, options);
    } else {
      throw this.error('cannotSaveWithMasterRepository', 'base-domain:cannot save with MasterRepository');
    }
  };


  /**
  Destroy the given entity (which must have "id" value)
  
  @method delete
  @public
  @param {Entity} entity
  @param {ResourceClientInterface} [client=@client]
  @return {Boolean} isDeleted
   */

  MasterRepository.prototype["delete"] = function() {
    throw this.error('cannotDeleteWithMasterRepository', 'base-domain:cannot delete with MasterRepository');
  };


  /**
  Update set of attributes.
  
  @method update
  @public
  @param {String|Number} id of the entity to update
  @param {Object} data key-value pair to update (notice: this must not be instance of Entity)
  @param {ResourceClientInterface} [client=@client]
  @return {Entity} updated entity
   */

  MasterRepository.prototype.update = function() {
    throw this.error('cannotUpdateWithMasterRepository', 'base-domain:cannot update with MasterRepository');
  };

  return MasterRepository;

})(BaseSyncRepository);

module.exports = MasterRepository;