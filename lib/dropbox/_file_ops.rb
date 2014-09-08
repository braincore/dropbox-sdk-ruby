module Dropbox
  module API
    module FileOps
      def copy(destination_path, opts = {})
        @client.files.copy(@path, destination_path, opts)
      end

      def delete(opts = {})
        @client.files.delete(@path, opts)
      end

      def move(destination_path, opts = {})
        @client.files.move(@path, destination_path, opts)
      end
    end
  end
end