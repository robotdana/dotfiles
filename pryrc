if defined?(Vertical) && Vertical.respond_to?(:set)
  Vertical.set(ENV['CURRENT_VERTICAL'])
end
