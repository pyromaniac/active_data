* Nested attributes support reference associations.

* References many association destruction works now the same way as embedded many one does. If any object was destroyed or marked for destruction - if will be moved to the destroyed array on `apply_changes` call (on the parent object saving).

* References one and many associations now don't destroy the object if it was marked for destruction, but the association is not autosave. In this case the object will be unlinked from the parent object and moved to the `destroyed` array for the references many association.

* No more `ActiveData.persistence_adapter` method. Define `self.active_data_persistence_adapter` directly in the desired class.

* Represented attributes are not provided by default, to add them, `include ActiveData::Model::Representation`

* `include ActiveData::Model::Associations::Validations` is not included by default anymore, to get `validate_ancestry!`, `valid_ancestry?` and `invalid_ancestry?` methods back you need to include this module manually.
