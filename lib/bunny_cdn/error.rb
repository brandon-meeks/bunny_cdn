module BunnyCdn
  class ApiError < StandardError
    attr_reader :status, :response

    def initialize(message, status:, response:)
      super(message)
      @status = status
      @response = response
    end
  end
end
