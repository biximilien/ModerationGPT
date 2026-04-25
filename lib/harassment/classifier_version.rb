module Harassment
  ClassifierVersion = Data.define(:value) do
    def self.build(value)
      normalized = value.to_s.strip
      raise ArgumentError, "classifier version must not be empty" if normalized.empty?

      new(value: normalized)
    end

    def to_s
      value
    end
  end
end
