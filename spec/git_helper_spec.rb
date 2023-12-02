RSpec.describe 'git helper spec' do
  describe 'git_web_url' do
    before { git("init") }

    it 'returns the github web url for https git' do
      git("remote add origin https://github.com/robotdana/dotfiles.git")
      expect(run 'git_web_url').to have_output(
        "https://github.com/robotdana/dotfiles\n"
      )
    end

    it 'returns the github web url for ssh git' do
      git("remote add upstream git@github.com:robotdana/dotfiles.git")
      expect(run 'git_web_url upstream').to have_output(
        "https://github.com/robotdana/dotfiles\n"
      )
    end

    it 'returns the bitbucket web url for https git' do
      git("remote add origin https://bitbucket.org/robotdana/dotfiles.git")
      expect(run 'git_web_url').to have_output(
        "https://bitbucket.org/robotdana/dotfiles\n"
      )
    end

    it 'returns the bitbucket web url for ssh git' do
      git("remote add upstream git@bitbucket.org:robotdana/dotfiles.git")
      expect(run 'git_web_url upstream').to have_output(
        "https://bitbucket.org/robotdana/dotfiles\n"
      )
    end

    it 'returns the gitlab web url for https git' do
      git("remote add origin https://gitlab.com/robotdana/dotfiles.git")
      expect(run 'git_web_url').to have_output(
        "https://gitlab.com/robotdana/dotfiles\n"
      )
    end

    it 'returns the gitlab web url for ssh git' do
      git("remote add upstream git@gitlab.com:robotdana/dotfiles.git")
      expect(run 'git_web_url upstream').to have_output(
        "https://gitlab.com/robotdana/dotfiles\n"
      )
    end
  end
end
