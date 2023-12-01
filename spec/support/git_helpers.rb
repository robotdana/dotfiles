module CLIHelper
  def git(args = nil, **kwargs)
    run("git #{args}", **kwargs)
  end

  def git_add(args, **kwargs)
    git("add #{args}", **kwargs)
  end

  def git_checkout(args, **kwargs)
    git("checkout #{args}", **kwargs)
  end

  def git_commit(args = nil, **kwargs)
    git("commit --no-gpg-sign #{args}", **kwargs)
  end

  def expect_clean_git_status
    result = git("status --long")
    expect(result.stdout).to have_output("On branch main\nnothing to commit, working tree clean\n")
    expect(result.stderr).to_not have_output
  end

  def expect_empty_git_stash
    result = git("stash list")
    expect(result.stdout).to_not have_output
    expect(result.stderr).to_not have_output
  end

  def expect_git_log(*log)
    result = git('log --format=%s')
    require 'pry'
    binding.pry

    expect(result.stdout).to have_output("#{log.join("\n")}\n")
    expect(result.stderr).to_not have_output
  end
end

RSpec.configure do |config|
  config.include CLIHelper
end
