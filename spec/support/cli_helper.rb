module CLIHelper
  def run(*args, **kwargs, &block)
    if args.empty?
      super("bash", '-l', expect_exit: false, **kwargs, &block)
    else
      super("bash", "-lc", Shellwords.join(args), **kwargs, &block)
    end
  end

  def git(*args, **kwargs)
    within_temp_dir

    run("git", *args, **kwargs)
  end

  def git_commit(*args, **kwargs)
    git("commit", "--no-gpg-sign", *args, **kwargs)
  end

  def expect_clean_git_status
    output do
      git("status","--long")
      expect(stdout).to have_output("On branch main\nnothing to commit, working tree clean\n")
      expect(stderr).to be_empty
    end
  end

  def expect_empty_git_stash
    output do
      git("stash", "list")
      expect(stdout).to be_empty
      expect(stderr).to be_empty
    end
  end

  def expect_git_log(*log)
    output do
      git('log', '--format=%s')
      expect(stdout).to have_output("#{log.join("\n")}\n")
      expect(stderr).to be_empty
    end
  end
end

RSpec.configure do |config|
  config.include CLIHelper
end
