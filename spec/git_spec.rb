RSpec.describe 'git', :aggregate_failures do
  within_temp_dir

  before do
    git("init")
    git_commit("--no-verify", "--allow-empty", "-m", "Initial commit")
  end

  it "doesn't stash when aborting commit" do
    create_file path: 'a-file-to-keep'
    git_commit("-m", "Empty commit that will abort", expect_exit: 1)
    expect_git_log "Initial commit"
    expect(file('a-file-to-keep')).to exist
  end

  it "cleans up when using amend" do
    create_file_list 'a', 'b'
    git("add", "a")
    git_commit("-m", "Original commit")
    git_commit("--amend", "-m", "Amended commit")
    git("add", "b")
    git_commit("--amend", "-m", "Amended commit with b")
    expect(file('a')).to exist
    expect(file('b')).to exist
    expect_clean_git_status
    expect_empty_git_stash
    expect_git_log "Amended commit with b", "Initial commit"
  end

  it 'resolves a merge conflict: theirs deleted: keep ours' do
    create_file_list('file1', 'file2')

    git('add', 'file1')
    git_commit("-m", "Commit 1")

    git("checkout", "-b", "branch2")
    git("rm", "file1")
    git("add", "file2")
    git_commit("-m", "Commit 2")
    git("checkout", "main")
    file("file1").write("amended text")
    git("add", "file1")
    git_commit("-m", "Commit 3")
    output do
      git("merge", "branch2", expect_exit: 1)
      expect(stdout).to have_output(<<~MESSAGE)  # why is this stdout?
        CONFLICT (modify/delete): file1 deleted in branch2 and modified in HEAD.  Version HEAD of file1 left in tree.
        Automatic merge failed; fix conflicts and then commit the result.
      MESSAGE
      expect(stderr).to be_empty
    end

    run do |stdin|
      stdin.puts 'yes n | gmc'
      expect(stdout).to have_output(end_with("Merge branch 'branch2'\n"))
    end

    expect_git_log("Merge branch 'branch2'", "Commit 3", "Commit 2", "Commit 1", "Initial commit")
    expect(file('file1')).to exist
    expect(file('file2')).to exist
    expect(file('file1').read).to eq('amended text')
  end

  it 'resolves a merge conflict: ours deleted: delete ours' do
    create_file_list('file1', 'file2')
    git('add', 'file1')
    git_commit('-m', 'Commit 1')
    git('checkout', '-b', 'branch2')
    file('file1').write('amended text')
    git('add', 'file1', 'file2')
    git_commit('-m', 'Commit 2')
    git('checkout', 'main')
    git('rm', 'file1')
    git('commit', '-m', 'Commit 3')
    output do
      git('merge', 'branch2', expect_exit: 1)
      expect(stdout).to have_output(<<~MESSAGE)
        CONFLICT (modify/delete): file1 deleted in HEAD and modified in branch2.  Version branch2 of file1 left in tree.
        Automatic merge failed; fix conflicts and then commit the result.
      MESSAGE
    end

    run do |stdin|
      stdin.puts 'yes n | gmc'
      expect(stdout).to have_output(end_with("Merge branch 'branch2'\n"))
    end

    expect_git_log("Merge branch 'branch2'", "Commit 3", "Commit 2", "Commit 1", "Initial commit")
    expect(file('file1')).to_not exist
    expect(file('file2')).to exist
  end

# @test "resolve merge conflict: ours deleted: keep theirs" {
#   echo 'text' > file1
#   git add file1
#   git commit -m "Commit 1"
#   git checkout -b "branch2"
#   echo 'amended text' > file1
#   git add file1
#   git commit -m "Commit 2"
#   git checkout main
#   rm file1
#   echo 'something' > file2
#   git add file1 file2
#   git commit -m "Commit 3"
#   run git merge branch2
#   assert_output --partial "CONFLICT (modify/delete): file1 deleted in HEAD and modified in branch2."
#   assert_output --partial "Version branch2 of file1 left in tree.
# Automatic merge failed; fix conflicts and then commit the result."
#   yes | run gmc
#   assert_file_exist file1
#   assert_file_exist file2
#   run git log --format=%s -n 1
#   assert_output "Merge branch 'branch2'"
#   run cat file1
#   assert_output 'amended text'
# }

# @test "resolve merge conflict: theirs deleted: delete ours" {
#   echo 'text' > file1
#   git add file1
#   git commit -m "Commit 1"
#   git checkout -b "branch2"
#   rm file1
#   git commit -am "Commit 2"
#   git checkout main
#   echo 'amended text' > file1
#   git add file1
#   git commit -m "Commit 3"
#   run git merge branch2
#   assert_output --partial "CONFLICT (modify/delete): file1 deleted in branch2 and modified in HEAD."
#   assert_output --partial "Version HEAD of file1 left in tree.
# Automatic merge failed; fix conflicts and then commit the result."
#   yes | run gmc
#   assert_file_not_exist file1
#   run git show --format="%s" HEAD
#   assert_output "Merge branch 'branch2'"
# }

end
