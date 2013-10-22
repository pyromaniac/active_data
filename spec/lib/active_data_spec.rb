# encoding: UTF-8
require 'spec_helper'

describe ActiveData do
  specify { subject.should respond_to :include_root_in_json }
  specify { subject.should respond_to :include_root_in_json= }
  specify { subject.should respond_to :i18n_scope }
  specify { subject.should respond_to :i18n_scope= }
  specify { subject.should respond_to :normalizer }
end
