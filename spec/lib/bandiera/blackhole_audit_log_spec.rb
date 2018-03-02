require 'spec_helper'

RSpec.describe Bandiera::BlackholeAuditLog do
  subject { Bandiera::BlackholeAuditLog.new }

  it_behaves_like 'an audit log'
end
