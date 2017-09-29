require 'spec_helper'

describe ActiveData do
  specify { expect(subject).to respond_to :include_root_in_json }
  specify { expect(subject).to respond_to :include_root_in_json= }
  specify { expect(subject).to respond_to :i18n_scope }
  specify { expect(subject).to respond_to :i18n_scope= }
  specify { expect(subject).to respond_to :primary_attribute }
  specify { expect(subject).to respond_to :primary_attribute= }
  specify { expect(subject).to respond_to :normalizer }
end
