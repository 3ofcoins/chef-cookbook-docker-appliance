module Docker
  class Container
    class << self
      def [](id)
        new(::Docker.connection, id)
      end
    end
  end
end
