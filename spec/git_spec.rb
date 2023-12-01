RSpec.describe 'git' do
  before do
    git("init")
    git_commit("--no-verify --allow-empty -m 'Initial commit'")
  end

  describe 'git hooks' do
    it "doesn't stash when aborting commit" do
      create_file path: 'a-file-to-keep'
      git_commit("-m 'Empty commit that will abort'", expect_exit: 1)
      expect(git_log).to have_output("Initial commit\n")
      expect(file('a-file-to-keep')).to exist
    end

    it "cleans up when using amend" do
      create_file_list 'a', 'b'
      git_add("a")
      git_commit("-m 'Original commit'")
      git_commit("--amend -m 'Amended commit'")
      git_add("b")
      git_commit("--amend -m 'Amended commit with b'")
      expect(file('a')).to exist
      expect(file('b')).to exist
      expect_clean_git_status
      expect(git("stash list")).to_not have_output
      expect(git_log).to have_output(["Amended commit with b", "Initial commit"], split: true)
    end
  end

  describe 'gmc (git_merge_continue)' do
    it 'resolves a merge conflict: theirs deleted: keep ours' do
      create_file_list('file1', 'file2')

      git_add('file1')
      git_commit("-m 'Commit 1'")

      git_checkout("-b branch2")
      git("rm file1")
      git_add("file2")
      git_commit("-m 'Commit 2'")
      git_checkout("main")
      file("file1").write("amended text")
      git_add("file1")
      git_commit("-m 'Commit 3'")
      expect(git("merge branch2", expect_exit: 1)).to have_output(<<~MESSAGE)
        CONFLICT (modify/delete): file1 deleted in branch2 and modified in HEAD.  Version HEAD of file1 left in tree.
        Automatic merge failed; fix conflicts and then commit the result.
      MESSAGE

      expect(run 'yes n | gmc').to have_output(stdout: end_with("Merge branch 'branch2'\n"))

      expect(git_log).to have_output(["Merge branch 'branch2'", "Commit 3", "Commit 2", "Commit 1", "Initial commit"], split: true)
      expect(file('file1')).to exist
      expect(file('file2')).to exist
      expect(file('file1').read).to eq('amended text')
    end

    it 'resolves a merge conflict: ours deleted: delete ours' do
      create_file_list('file1', 'file2')
      git_add('file1')
      git_commit("-m 'Commit 1'")
      git('checkout -b branch2')
      file('file1').write('amended text')
      git_add('file1 file2')
      git_commit("-m 'Commit 2'")
      git('checkout main')
      git('rm file1')
      git("commit -m 'Commit 3'")
      expect(git('merge branch2', expect_exit: 1)).to have_output(<<~MESSAGE)
        CONFLICT (modify/delete): file1 deleted in HEAD and modified in branch2.  Version branch2 of file1 left in tree.
        Automatic merge failed; fix conflicts and then commit the result.
      MESSAGE
      expect(run('yes n | gmc')).to have_output(stdout: end_with("Merge branch 'branch2'\n"))
      expect(git_log).to have_output(["Merge branch 'branch2'", "Commit 3", "Commit 2", "Commit 1", "Initial commit"], split: true)
      expect(file('file1')).to_not exist
      expect(file('file2')).to exist
    end

    it "resolves a merge conflict: ours deleted: keep theirs" do
      create_file('text', path: 'file1')
      git_add("file1")
      git_commit("-m 'Commit 1'")
      git_checkout("-b branch2")
      file('file1').write('amended text')
      git_add('file1')
      git_commit('-m "Commit 2"')
      git_checkout('main')
      git('rm file1')
      file('file2').write('something')
      git_add('file2')
      git_commit("-m 'Commit 3'")
      expect(git('merge branch2', expect_exit: 1)).to have_output(<<~MESSAGE)
        CONFLICT (modify/delete): file1 deleted in HEAD and modified in branch2.  Version branch2 of file1 left in tree.
        Automatic merge failed; fix conflicts and then commit the result.
      MESSAGE
      run('yes | gmc')
      expect(file('file1')).to exist
      expect(file('file2')).to exist
      expect(git_log).to have_output(["Merge branch 'branch2'", 'Commit 3', 'Commit 2', 'Commit 1', 'Initial commit'], split: true)
      expect(file('file1').read).to eq 'amended text'
    end

    it "resolves a merge conflict: theirs deleted: delete ours" do
      file('file1').write('text')
      git_add('file1')
      git_commit('-m "Commit 1"')
      git_checkout('-b "branch2"')
      git('rm file1')
      git_commit('-am "Commit 2"')
      git_checkout('main')
      file('file1').write('amended text')
      git_add('file1')
      git_commit('-m "Commit 3"')
      expect(git('merge branch2', expect_exit: 1)).to have_output(<<~MESSAGE)
        CONFLICT (modify/delete): file1 deleted in branch2 and modified in HEAD.  Version HEAD of file1 left in tree.
        Automatic merge failed; fix conflicts and then commit the result.
      MESSAGE
      run('yes | gmc')
      expect(file('file1')).to_not exist
      expect(git_log).to have_output(["Merge branch 'branch2'", 'Commit 3', 'Commit 2', 'Commit 1', 'Initial commit'], split: true)
    end
  end

  describe 'git_reword' do
    it "can reword the commit message" do
      git_checkout("-b branch")
      file('a').write('a')
      git_add('.')
      git_commit('-m "Commit message to be changed"')
      file('b').write('b')
      git_add('.')
      git_commit('-m "Commit message to remain"')
      sha_by_name = run("git_find_sha to be changed")
      expect(sha_by_name).to have_output(/\A\h+\n\z/)
      sha_by_alias = run("git rev-parse --short HEAD^")
      expect(sha_by_alias).to have_output(/\A\h+\n\z/)
      expect(sha_by_name.output.to_s).to eq sha_by_alias.output.to_s
      expect(run("git_reword 'to be changed'", env: { GIT_EDITOR: "sed -i.~ s/to\\ be\\ changed/was\\ changed/" }))
        .to_not have_output
      expect(git_log).to have_output(["commit message to remain", "Commit message was changed", "Initial commit"], split: true)
    end
  end
end
