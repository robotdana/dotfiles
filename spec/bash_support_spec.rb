# frozen_string_literal: true

RSpec.describe 'bash_support' do
  it 'returns current ruby version' do
    copy_file '.ruby-version'
    expect(run('ruby -v')).to have_output(
      "ruby 3.2.2 (2023-03-30 revision e51014f9c0) [x86_64-darwin22]\n"
    )
  end

  describe 'echoerr' do
    it 'returns red text for echoerr' do
      expect(run('echoerr No', exit_with: 1)).to have_output(
        stderr: "\e[31merror: No\e[0m\n",
        stdout: nil
      )
    end
  end

  describe 'echodo' do
    it 'returns grey text for echodo to stderr and does the thing to stdout' do
      expect(run('echodo echo 1')).to have_output(
        stderr: "\e[0;2mecho 1\e[0m\n",
        stdout: "1\n"
      )
    end

    it 'removes unnecessary single quotes' do
      expect(run("echodo echo '1'")).to have_output(
        stderr: "\e[0;2mecho 1\e[0m\n",
        stdout: "1\n"
      )
    end

    it 'removes unnecessary double quotes' do
      expect(run('echodo echo "1"')).to have_output(
        stderr: "\e[0;2mecho 1\e[0m\n",
        stdout: "1\n"
      )
    end

    it 'retains quoted empty double quoted strings' do
      expect(run('echodo echo ""')).to have_output(
        stderr: "\e[0;2mecho ''\e[0m\n",
        stdout: "\n"
      )
    end

    it 'retains quoted empty single quoted strings' do
      expect(run("echodo echo ''")).to have_output(
        stderr: "\e[0;2mecho ''\e[0m\n",
        stdout: "\n"
      )
    end

    it 'uses single quotes to escape spaces when given a single quoted string' do
      expect(run("echodo echo '1 and 2'")).to have_output(
        stderr: "\e[0;2mecho '1 and 2'\e[0m\n",
        stdout: "1 and 2\n"
      )
    end

    it 'uses single quotes to escape spaces when given a double quoted string' do
      expect(run('echodo echo "1 and 2"')).to have_output(
        stderr: "\e[0;2mecho '1 and 2'\e[0m\n",
        stdout: "1 and 2\n"
      )
    end

    it 'uses single quotes to escape spaces when given a backslash escaped string' do
      expect(run('echodo echo 1\\ and\\ 2')).to have_output(
        stderr: "\e[0;2mecho '1 and 2'\e[0m\n",
        stdout: "1 and 2\n"
      )
    end

    it 'uses single quotes to escape \\(whatever\\)' do
      expect(run('echodo echo \\(whatever\\)')).to have_output(
        stderr: "\e[0;2mecho '(whatever)'\e[0m\n",
        stdout: "(whatever)\n"
      )
    end

    it "uses single quotes to escape '(whatever)'" do
      expect(run("echodo echo '(whatever)'")).to have_output(
        stderr: "\e[0;2mecho '(whatever)'\e[0m\n",
        stdout: "(whatever)\n"
      )
    end

    it "uses single quotes to escape '[whatever]" do
      expect(run("echodo echo '[whatever]'")).to have_output(
        stderr: "\e[0;2mecho '[whatever]'\e[0m\n",
        stdout: "[whatever]\n"
      )
    end

    it "uses single quotes to escape 'what)ever]'" do
      expect(run("echodo echo 'what)ever]'")).to have_output(
        stderr: "\e[0;2mecho 'what)ever]'\e[0m\n",
        stdout: "what)ever]\n"
      )
    end

    it "uses single quotes to escape 'what) ever]'" do
      expect(run("echodo echo 'what) ever]'")).to have_output(
        stderr: "\e[0;2mecho 'what) ever]'\e[0m\n",
        stdout: "what) ever]\n"
      )
    end

    it "uses single quotes to escape 'what)ever'" do
      expect(run("echodo echo 'what)ever'")).to have_output(
        stderr: "\e[0;2mecho 'what)ever'\e[0m\n",
        stdout: "what)ever\n"
      )
    end

    it "uses single quotes to escape 'what>ever'" do
      expect(run("echodo echo 'what>ever'")).to have_output(
        stderr: "\e[0;2mecho 'what>ever'\e[0m\n",
        stdout: "what>ever\n"
      )
    end

    it "uses single quotes to escape 'what<ever'" do
      expect(run("echodo echo 'what<ever'")).to have_output(
        stderr: "\e[0;2mecho 'what<ever'\e[0m\n",
        stdout: "what<ever\n"
      )
    end

    it "uses single quotes to escape 'what\\n\\never'" do
      expect(run("echodo echo 'what\n\never'")).to have_output(
        stderr: "\e[0;2mecho 'what\n\never'\e[0m\n",
        stdout: "what\n\never\n"
      )
    end

    it "uses single quotes to escape '$dance'" do
      expect(run("echodo echo '$dance'")).to have_output(
        stderr: "\e[0;2mecho '$dance'\e[0m\n",
        stdout: "$dance\n"
      )
    end

    it %{uses single quotes to escape '"$dance"'} do
      expect(run(%{echodo echo '"$dance"'})).to have_output(
        stderr: %{\e[0;2mecho '"$dance"'\e[0m\n},
        stdout: %{"$dance"\n}
      )
    end

    it 'uses double quotes to escape single quotes' do
      expect(run("echodo echo don\\'t")).to have_output(
        stderr: %{\e[0;2mecho "don't"\e[0m\n},
        stdout: "don't\n"
      )
    end

    it 'uses single quotes to escape double quotes' do
      expect(run(%{echodo echo 'do or do not there is no "try"'}))
        .to have_output(
          stderr: %{\e[0;2mecho 'do or do not there is no "try"'\e[0m\n},
          stdout: %{do or do not there is no "try"\n}
        )
    end

    it 'uses double quotes to escape both types of quotes' do
      # because "\"" works and '\'' doesn't
      expect(run(%{echodo echo "do or don't "'there is no "try"'}))
        .to have_output(
          stderr: %{\e[0;2mecho "do or don't there is no \\"try\\""\e[0m\n},
          stdout: %{do or don't there is no "try"\n}
        )
    end

    it "doesn't escape !" do
      # I never want history expansion
      # so I `set +H` in bash_profile
      # so I don't need to escape `!`
      expect(run(%{echodo echo !})).to have_output(
        stderr: %{\e[0;2mecho !\e[0m\n},
        stdout: %{!\n}
      )
    end
  end
end
