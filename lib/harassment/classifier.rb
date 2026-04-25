module Harassment
  class Classifier
    def classify(_event:, _classifier_version:, classified_at: Time.now.utc)
      raise NotImplementedError, "#{self.class} must implement #classify"
    end
  end
end
