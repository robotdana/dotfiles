# frozen_string_literal: true

COLOR_RED = ENV.fetch('COLOR_RED')
COLOR_GREEN = ENV.fetch('COLOR_GREEN')
COLOR_YELLOW = ENV.fetch('COLOR_YELLOW')
COLOR_BLUE = ENV.fetch('COLOR_BLUE')
COLOR_AQUA = ENV.fetch('COLOR_AQUA')
COLOR_GREY = ENV.fetch('COLOR_GREY')
COLOR_PINK = ENV.fetch('COLOR_PINK')
COLOR_RESET = ENV.fetch('COLOR_RESET')
COLOR_LIGHT_PINK = ENV.fetch('COLOR_LIGHT_PINK')

RSpec.describe 'bash_support' do
  it 'returns current ruby version' do
    copy_file '.ruby-version'
    expect(run('ruby -v')).to have_output(
      "ruby 3.2.2 (2023-03-30 revision e51014f9c0) [x86_64-darwin22]\n"
    )
  end

  describe 'echoerr' do
    it 'returns red text for echoerr' do
      expect(run('echoerr No', expect_exit: 1)).to have_output(
        stderr: "#{COLOR_RED}error: No#{COLOR_RESET}\n",
        stdout: nil
      )
    end
  end

  describe 'echodo' do
    it 'returns grey text for echodo to stderr and does the thing to stdout' do
      expect(run('echodo echo 1')).to have_output(
        stderr: "#{COLOR_GREY}echo 1#{COLOR_RESET}\n",
        stdout: "1\n"
      )
    end

    it 'removes unnecessary single quotes' do
      expect(run("echodo echo '1'")).to have_output(
        stderr: "#{COLOR_GREY}echo 1#{COLOR_RESET}\n",
        stdout: "1\n"
      )
    end

    it 'removes unnecessary double quotes' do
      expect(run('echodo echo "1"')).to have_output(
        stderr: "#{COLOR_GREY}echo 1#{COLOR_RESET}\n",
        stdout: "1\n"
      )
    end

    it 'retains quoted empty double quoted strings' do
      expect(run('echodo echo ""')).to have_output(
        stderr: "#{COLOR_GREY}echo ''#{COLOR_RESET}\n",
        stdout: "\n"
      )
    end

    it 'retains quoted empty single quoted strings' do
      expect(run("echodo echo ''")).to have_output(
        stderr: "#{COLOR_GREY}echo ''#{COLOR_RESET}\n",
        stdout: "\n"
      )
    end

    it 'uses single quotes to escape spaces when given a single quoted string' do
      expect(run("echodo echo '1 and 2'")).to have_output(
        stderr: "#{COLOR_GREY}echo '1 and 2'#{COLOR_RESET}\n",
        stdout: "1 and 2\n"
      )
    end

    it 'uses single quotes to escape spaces when given a double quoted string' do
      expect(run('echodo echo "1 and 2"')).to have_output(
        stderr: "#{COLOR_GREY}echo '1 and 2'#{COLOR_RESET}\n",
        stdout: "1 and 2\n"
      )
    end

    it 'uses single quotes to escape spaces when given a backslash escaped string' do
      expect(run('echodo echo 1\\ and\\ 2')).to have_output(
        stderr: "#{COLOR_GREY}echo '1 and 2'#{COLOR_RESET}\n",
        stdout: "1 and 2\n"
      )
    end

    it 'uses single quotes to escape \\(whatever\\)' do
      expect(run('echodo echo \\(whatever\\)')).to have_output(
        stderr: "#{COLOR_GREY}echo '(whatever)'#{COLOR_RESET}\n",
        stdout: "(whatever)\n"
      )
    end

    it "uses single quotes to escape '(whatever)'" do
      expect(run("echodo echo '(whatever)'")).to have_output(
        stderr: "#{COLOR_GREY}echo '(whatever)'#{COLOR_RESET}\n",
        stdout: "(whatever)\n"
      )
    end

    it "uses single quotes to escape '[whatever]" do
      expect(run("echodo echo '[whatever]'")).to have_output(
        stderr: "#{COLOR_GREY}echo '[whatever]'#{COLOR_RESET}\n",
        stdout: "[whatever]\n"
      )
    end

    it "uses single quotes to escape 'what)ever]'" do
      expect(run("echodo echo 'what)ever]'")).to have_output(
        stderr: "#{COLOR_GREY}echo 'what)ever]'#{COLOR_RESET}\n",
        stdout: "what)ever]\n"
      )
    end

    it "uses single quotes to escape 'what) ever]'" do
      expect(run("echodo echo 'what) ever]'")).to have_output(
        stderr: "#{COLOR_GREY}echo 'what) ever]'#{COLOR_RESET}\n",
        stdout: "what) ever]\n"
      )
    end

    it "uses single quotes to escape 'what)ever'" do
      expect(run("echodo echo 'what)ever'")).to have_output(
        stderr: "#{COLOR_GREY}echo 'what)ever'#{COLOR_RESET}\n",
        stdout: "what)ever\n"
      )
    end

    it "uses single quotes to escape 'what>ever'" do
      expect(run("echodo echo 'what>ever'")).to have_output(
        stderr: "#{COLOR_GREY}echo 'what>ever'#{COLOR_RESET}\n",
        stdout: "what>ever\n"
      )
    end

    it "uses single quotes to escape 'what<ever'" do
      expect(run("echodo echo 'what<ever'")).to have_output(
        stderr: "#{COLOR_GREY}echo 'what<ever'#{COLOR_RESET}\n",
        stdout: "what<ever\n"
      )
    end

    it "uses single quotes to escape 'what\\n\\never'" do
      expect(run("echodo echo 'what\n\never'")).to have_output(
        stderr: "#{COLOR_GREY}echo 'what\n\never'#{COLOR_RESET}\n",
        stdout: "what\n\never\n"
      )
    end

    it "uses single quotes to escape '$dance'" do
      expect(run("echodo echo '$dance'")).to have_output(
        stderr: "#{COLOR_GREY}echo '$dance'#{COLOR_RESET}\n",
        stdout: "$dance\n"
      )
    end

    it %{uses single quotes to escape '"$dance"'} do
      expect(run(%{echodo echo '"$dance"'})).to have_output(
        stderr: %{#{COLOR_GREY}echo '"$dance"'#{COLOR_RESET}\n},
        stdout: %{"$dance"\n}
      )
    end

    it 'uses double quotes to escape single quotes' do
      expect(run("echodo echo don\\'t")).to have_output(
        stderr: %{#{COLOR_GREY}echo "don't"#{COLOR_RESET}\n},
        stdout: "don't\n"
      )
    end

    it 'uses single quotes to escape double quotes' do
      expect(run(%{echodo echo 'do or do not there is no "try"'}))
        .to have_output(
          stderr: %{#{COLOR_GREY}echo 'do or do not there is no "try"'#{COLOR_RESET}\n},
          stdout: %{do or do not there is no "try"\n}
        )
    end

    it 'uses double quotes to escape both types of quotes' do
      # because "\"" works and '\'' doesn't
      expect(run(%{echodo echo "do or don't "'there is no "try"'}))
        .to have_output(
          stderr: %{#{COLOR_GREY}echo "do or don't there is no \\"try\\""#{COLOR_RESET}\n},
          stdout: %{do or don't there is no "try"\n}
        )
    end

    it "doesn't escape !" do
      # I never want history expansion
      # so I `set +H` in bash_profile
      # so I don't need to escape `!`
      expect(run(%{echodo echo !})).to have_output(
        stderr: %{#{COLOR_GREY}echo !#{COLOR_RESET}\n},
        stdout: %{!\n}
      )
    end
  end
end
