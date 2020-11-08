if defined?(Vertical) && Vertical.respond_to?(:set)
  def v(vertical = nil)
    ActiveRecord::Base.logger.silence do
      Vertical.set(vertical || :marketplacer)
    end
  end

  v unless Vertical.set?
end


Pry.config.pager = false

prompts = [
  proc { |obj, nest_level, pry| "\e[34m #{pry.input_ring.count.to_s.rjust 3}\e[90m ⎸\e[0m" },
  proc { |obj, nest_level, pry| "\e[31m…\e[34m#{pry.input_ring.count.to_s.rjust 3}\e[90m ⎸\e[0m" }
]
Pry.config.prompt = Pry::Prompt.respond_to?(:new) ? Pry::Prompt.new("custom","custom prompt", prompts) : prompts
Pry.config.output_prefix = "\e[34m   -\e[90m ⎸\e[0m"

def pbcopy(str)
  IO.popen('pbcopy', 'r+') { |io| io.puts str }
end

Pry.config.commands.command 'copy', 'Copy to clipboard' do |str|
  pbcopy(str || _pry_.last_result.to_s.chomp)
end
