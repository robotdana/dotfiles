if defined?(Vertical) && Vertical.respond_to?(:set)
  def v(vertical = nil)
    ActiveRecord::Base.logger.silence do
      vertical ||= Vertical.verticals.keys.find { |vt| vt == ENV['CURRENT_VERTICAL'] }
      vertical ||= Vertical.verticals.keys.first
      Vertical.set(vertical) if vertical
    end
  end

  v
end

def pbcopy(str)
  IO.popen('pbcopy', 'r+') { |io| io.puts str }
end

Pry.config.commands.command 'copy', 'Copy to clipboard' do |str|
  pbcopy(str || _pry_.last_result.to_s.chomp)
end
