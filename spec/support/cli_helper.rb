module CLIHelper
  def run(*cmd)
    cmd = if cmd.empty?
      ["bash", '-l']
    else
      ["bash", "-lc", Shellwords.join(cmd)]
    end

    super(*cmd)
  end
end

RSpec.configure do |config|
  config.include CLIHelper
end
