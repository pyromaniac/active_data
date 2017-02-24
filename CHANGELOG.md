* Represented attributes are not provided by default, to add them, `include ActiveData::Model::Representation`

* `include ActiveData::Model::Associations::Validations` is not included by default anymore, to get `validate_ancestry!`, `valid_ancestry?` and `invalid_ancestry?` methods back you neet to include this module manually.
