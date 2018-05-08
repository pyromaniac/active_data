# master

# Version 1.1.1

## Changes

* `ActiveData.base_class` config option (#63)

* ActiveModel 5.2 compatibility (#62)

# Version 1.1.0

## Incompatible changes

* Represented attributes are not provided by default, to add them, `include ActiveData::Model::Representation` (#46)

* `include ActiveData::Model::Associations::Validations` is not included by default anymore, to get `validate_ancestry!`, `valid_ancestry?` and `invalid_ancestry?` methods back you need to include this module manually

## Changes

* Introduce persistence adapters for associations (#24, #51)

* `ActionController::Parameters` support (#43)

* Nested attributes simple method overriding (#41)

* Persistence for `references` associations (#28, #32)

* Support `update_only` option on collection nested attributes (#30)

* `embedder` accessor for embedded associations

* Dynamic scopes for `references` associations (#27)

## Bugfixes

* Fixed multiple validations on represented attributes and associations (#44)

* Proper boolean attributes defaults (#31, #33)
