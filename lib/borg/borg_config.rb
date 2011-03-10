module Borg
  class Config
    class << self
      def load_config(config_file)
        @@borg_config = YAML.load(File.open(config_file))
      end
      def method_missing(*args,&block)
        method_name = args.first.to_s
        @@borg_config[method_name]
      end
    end
  end
end

