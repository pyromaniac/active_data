# encoding: UTF-8
require 'spec_helper'

describe ActiveData::Config do
  subject { ActiveData::Config.send :new }

  its(:include_root_in_json) { should be_false }
  specify { expect { subject.include_root_in_json = true }
    .to change { subject.include_root_in_json }.from(false).to(true) }
end
