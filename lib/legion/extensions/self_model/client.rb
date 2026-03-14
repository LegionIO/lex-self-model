# frozen_string_literal: true

module Legion
  module Extensions
    module SelfModel
      class Client
        include Runners::SelfModel

        def initialize(model: nil)
          @model = model || Helpers::SelfModel.new
        end
      end
    end
  end
end
