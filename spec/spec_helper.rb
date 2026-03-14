# frozen_string_literal: true

require 'legion/extensions/self_model/version'
require 'legion/extensions/self_model/helpers/constants'
require 'legion/extensions/self_model/helpers/capability'
require 'legion/extensions/self_model/helpers/knowledge_domain'
require 'legion/extensions/self_model/helpers/self_model'
require 'legion/extensions/self_model/runners/self_model'
require 'legion/extensions/self_model/client'

module Legion
  module Extensions
    module Helpers
      module Lex; end
    end
  end
end

module Legion
  module Logging
    def self.method_missing(*); end
    def self.respond_to_missing?(*) = true
  end
end
