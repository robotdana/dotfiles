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
    expect(git("status --long")).to have_output("On branch main\nnothing to commit, working tree clean\n")
  end

  def expect_empty_stash
    expect(git("stash list")).to_not have_output
  end

  def git_log
    git('log --format=%s')
  end
end

RSpec.configure do |config|
  config.include CLIHelper
end
