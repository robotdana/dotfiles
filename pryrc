if defined?(Vertical) && Vertical.respond_to?(:set)
  def v vertical=ENV['CURRENT_VERTICAL']
    ActiveRecord::Base.logger.silence do
      Vertical.set(vertical) if vertical
    end
  end

  v
end
