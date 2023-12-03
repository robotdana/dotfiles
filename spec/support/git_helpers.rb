# frozen_string_literal: true

module CLIHelper
  def git(args = nil, **)
    run("git #{args}", **)
  end

  def git_add(args, **)
    git("add #{args}", **)
  end

  def git_checkout(args, **)
    git("checkout #{args}", **)
  end

  def git_commit(args = nil, **)
    git("commit --no-gpg-sign #{args}", **)
  end

  def expect_clean_git_status
    expect(git('status --long')).to have_output(<<~MESSAGE)
      On branch main
      nothing to commit, working tree clean
    MESSAGE
  end

  def expect_empty_stash
    expect(git('stash list')).not_to have_output
  end

  def git_log
    git('log --format=%s')
  end
end

RSpec.configure do |config|
  config.include CLIHelper
end
