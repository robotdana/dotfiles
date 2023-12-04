# frozen_string_literal: true

RSpec.describe 'git rubocop hooks' do
  before do
    copy_file('.ruby-version')
    file('Gemfile').write(<<~RUBY)
      source 'https://rubygems.org'
      gem 'rubocop', '1.55.1'
    RUBY
    file('.rubocop.yml').write(<<~YML)
      AllCops:
        NewCops: enable
    YML
    run('bundle install --prefer-local', wait: 60)
    git('init')
    git_add('.')
    git_commit('--no-verify -m "Initial commit"')
  end

  let(:good_rb) do
    <<~RUBY
      # frozen_string_literal: true

      def foo
        puts true
      end
    RUBY
  end

  let(:bad_rb) do
    <<~RUBY
      # frozen_string_literal: true

      def bar(unused_keyword: true)
        puts true
        puts true
        puts true
        puts true
        puts true
        puts true
        puts true
        puts true
        puts true
      end
    RUBY
  end

  let(:bad_autofixable_rb) do
    <<~RUBY
      def foo()

        puts true

      end
    RUBY
  end

  it 'commits when passing the rubocop hook' do
    file('foo.rb').write(good_rb)
    file('bar.rb').write(good_rb)
    git_add('.')
    run 'gc Pass rubocop'
    expect_clean_git_status
    expect_empty_stash
    expect(git_log)
      .to have_output(['Pass rubocop', 'Initial commit'], split: true)
    expect(file('foo.rb')).to exist
    expect(file('bar.rb')).to exist
  end

  it 'pauses for correction when failing the rubocop hook' do
    file('foo.rb').write(bad_rb)
    file('bar.rb').write(bad_rb)
    git_add('.')
    run('gc Fail rubocop', exit_with: be_nonzero)
    run('git_rebasing') # paused rebase for fixing
    file('foo.rb').write(good_rb)
    file('bar.rb').write(good_rb)
    run('grc', wait: 5) do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('y')

      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('y')
    end
    expect_clean_git_status
    expect_empty_stash
    run('git_rebasing', exit_with: be_nonzero) # no longer rebasing
  end

  it 'asks to patch add autocorrections when failing the rubocop hook' do
    file('foo.rb').write(bad_autofixable_rb)
    file('bar.rb').write(bad_autofixable_rb)
    git_add('.')
    run('gc Auto rubocop') do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,s,e,?]? '), wait: 10)
      cmd.stdin.puts('y')
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,s,e,?]? '), wait: 20)
      cmd.stdin.puts('y')
    end

    run('git_rebasing', exit_with: be_nonzero) # completed rebase
    expect_clean_git_status
    expect_empty_stash

    expect(file('foo.rb').read).to eq good_rb
    expect(file('bar.rb').read).to eq good_rb
  end

  # TODO: make this less manual
  it 'partial add pass rubocop hook' do
    file('foo.rb').write(good_rb)
    file('bar.rb').write(bad_rb)
    git_add('foo.rb')
    run('gc Pass rubocop', exit_with: be_nonzero, wait: 10) do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage addition [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('q')
    end
    # it fails due to the rebase not attempting, but does make the commit:
    expect(git_log)
      .to have_output(['Pass rubocop', 'Initial commit'], split: true)
    expect(run('git show --pretty=format: --name-only'))
      .to have_output("foo.rb\n")

    run('git_rebasing', exit_with: be_nonzero)
    expect(run('git_untracked')).to have_output("bar.rb\n")

    # manually lint, TODO: remove this step
    run('git_stash_only_untracked')
    run('git_autolint_head')
    run('git_rebasing', exit_with: be_nonzero)
    run('git stash pop')

    expect(run('git_untracked')).to have_output("bar.rb\n")
  end

  # TODO: make this less manual
  it 'partial add fail rubocop hook' do
    file('foo.rb').write(good_rb)
    file('bar.rb').write(bad_rb)
    git_add('bar.rb')
    run('gc Pass rubocop', exit_with: be_nonzero, wait: 10) do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage addition [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('q')
    end
    # it fails due to the rebase not attempting, but does make the commit:
    expect(git_log)
      .to have_output(
        ['Pass rubocop', 'Initial commit'], split: true
      )
    expect(run('git show --pretty=format: --name-only'))
      .to have_output("bar.rb\n")

    run('git_rebasing', exit_with: be_nonzero)
    expect(run('git_untracked')).to have_output("foo.rb\n")

    # manually lint, TODO: remove this step
    run('git_stash_only_untracked')
    run('git_autolint_head', exit_with: be_nonzero)
    run('git_rebasing')
    file('bar.rb').write(good_rb)
    run('grc') do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('y')
    end
    run('git_rebasing', exit_with: be_nonzero)

    run('git stash pop')
    expect(run('git_untracked')).to have_output("foo.rb\n")
  end

  it 'partial add autocorrect rubocop hook' do
    file('bar.rb').write(bad_autofixable_rb)
    file('foo.rb').write(good_rb)
    git_add('bar.rb')
    run('gc Auto rubocop', exit_with: be_nonzero) do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage addition [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('q')
    end
    # this doesn't run rubocop because there are untracked files
    run('git_rebasing', exit_with: be_nonzero)
    expect(run('git_untracked')).to have_output("foo.rb\n")

    # manually lint
    run('git_stash_only_untracked')
    run('git_autolint_head') do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,s,e,?]? '), wait: 10)

      cmd.stdin.puts('y')
    end
    run('git_rebasing', exit_with: be_nonzero)
    git('stash pop')
    expect(run('git_untracked')).to have_output("foo.rb\n")
  end

  it 'patch add pass rubocop hook' do
    file('foo.rb').write(good_rb)
    git_add('foo.rb')
    file('foo.rb').open('a') do |f|
      f << bad_rb
    end
    expect(run 'git diff --cached --name-only')
      .to have_output("foo.rb\n")
    expect(run 'git diff --name-only')
      .to have_output("foo.rb\n")

    run('gc Pass rubocop') do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('n')
    end
    run('git_rebasing', exit_with: be_nonzero)
    expect(file('foo.rb').read).to eq "#{good_rb}#{bad_rb}"
  end

  it 'patch add fail rubocop hook' do
    file('foo.rb').write(bad_rb)
    git_add('foo.rb')
    file('foo.rb').open('a') do |f|
      f << good_rb
    end
    expect(run 'git diff --cached --name-only')
      .to have_output("foo.rb\n")
    expect(run 'git diff --name-only')
      .to have_output("foo.rb\n")
    run('gc Fail rubocop', exit_with: be_nonzero) do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('n')
    end
    run('git_rebasing')
    file('foo.rb').write(good_rb)
    run('grc') do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('y')
    end
    run('git_rebasing', exit_with: be_nonzero)
    expect(file('foo.rb').read).to eq "#{good_rb}#{good_rb}"
  end

  it 'patch add autocorrect rubocop hook' do
    file('foo.rb').write(bad_autofixable_rb)
    git_add('foo.rb')
    file('foo.rb').open('a') do |f|
      f << "# comment\n"
    end
    expect(run 'git diff --cached --name-only')
      .to have_output("foo.rb\n")
    expect(run 'git diff --name-only')
      .to have_output("foo.rb\n")
    run('gc Auto rubocop') do |cmd|
      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,e,?]? '), wait: 10)

      cmd.stdin.puts('n') # the comment

      expect(cmd).to have_output(stdout: end_with('(1/1) Stage this hunk [y,n,q,a,d,s,e,?]? '), wait: 10)

      cmd.stdin.puts('y') # the correction
    end
    run('git_rebasing', exit_with: be_nonzero)
    expect(file('foo.rb').read).to eq "#{good_rb}# comment\n"
  end
end

# @test "patch add conflict fail rubocop hook" {
#   bad_rb > foo.rb
#   git add foo.rb
#   good_rb > foo.rb
#   echo "CONFLICT = false" >> foo.rb
#   ( yes q | RBENV_VERSION=3.2.2 rbenv exec gc "Fail rubocop" ) || true
#   assert git_rebasing
#   good_rb > foo.rb
#   echo "CONFLICTED = true" >> foo.rb
#   yes | RBENV_VERSION=3.2.2 rbenv exec grc
#   refute git_rebasing

#   run git log --format="%s"
#   assert_output "Fail rubocop
# Initial commit"
#   # assert_git_stash_empty
#   assert_equal "$(cat foo.rb)" "$(good_rb)
# <<<<<<< Updated upstream
# CONFLICTED = true
# ||||||| Stash base
# =======
# CONFLICT = false
# >>>>>>> Stashed changes"
# }

# end
