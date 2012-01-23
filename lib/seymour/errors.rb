module Seymour
  class SeymourError < StandardError
  end

  class InvalidActivity < SeymourError
  end

  class InvalidDistribution < SeymourError
    attr_reader :message

    def initialize message
      @message = "Invalid Distribution: #{message}"
    end
  end

  # This error is raised when an object isn't defined
  # as an actor, object or target
  #
  # Example:
  #
  # <tt>InvalidField.new('field_name')</tt>
  class InvalidData < SeymourError
    attr_reader :message

    def initialize message
      @message = "Invalid Data: #{message}"
    end
  end

  # This error is raised when trying to store a field that doesn't exist
  #
  # Example:
  #
  # <tt>InvalidField.new('field_name')</tt>
  class InvalidField < SeymourError
    attr_reader :message

    def initialize message
      @message = "Invalid Field: #{message}"
    end
  end
end