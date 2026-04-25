require_relative "../classification_status"
require_relative "../interaction_event"

module Harassment
  module Repositories
    class InteractionEventRepository
      def save(_event)
        raise NotImplementedError, "#{self.class} must implement #save"
      end

      def find(_message_id)
        raise NotImplementedError, "#{self.class} must implement #find"
      end

      def update_classification_status(_message_id, _status)
        raise NotImplementedError, "#{self.class} must implement #update_classification_status"
      end

      def list_by_classification_status(_status)
        raise NotImplementedError, "#{self.class} must implement #list_by_classification_status"
      end
    end
  end
end
