module Twinfield
  class Session
    attr_accessor :access_token, :cluster, :company

    def initialize
      @access_token = nil
      @cluster = nil
      @company = nil
    end

    def logon
      @access_token = Twinfield.configuration.access_token
      @cluster = Twinfield.configuration.cluster
      @company= Twinfield.configuration.company
    end

    def connected?
      @access_token && @cluster && @company
    end
  end
end
