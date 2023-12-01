C_RED = "\033[38;5;125m"
C_GREEN = "\033[38;5;48m"
C_YELLOW = "\033[38;5;227m"
C_BLUE = "\033[1;34m"
C_AQUA = "\033[1;36m"
C_GREY = "\033[0;90m"
C_PINK = "\033[38;5;199m"
C_RESET = "\033[0m"
C_LIGHT_PINK = "\033[38;5;205m"

RSpec.describe 'bash_support', :aggregate_failures do
  it 'returns current ruby version' do
    copy_file '.ruby-version'
    run 'ruby -v'

    expect(stdout).to have_output "ruby 3.2.2 (2023-03-30 revision e51014f9c0) [x86_64-darwin22]\n"
    expect(stderr).to_not have_output
  end

  describe 'echoerr' do
    it 'returns red text for echoerr' do
      run 'echoerr No', expect_exit: 1

      expect(stderr).to have_output "#{C_RED}No#{C_RESET}\n"
      expect(stdout).to_not have_output
    end
  end

  describe 'echodo' do
    it 'returns grey text for echodo to stderr and does the thing to stdout' do
      run "echodo echo 1"

      expect(stderr).to have_output "#{C_GREY}echo 1#{C_RESET}\n"
      expect(stdout).to have_output "1\n"
    end

    it 'removes unnecessary single quotes' do
      run "echodo echo '1'"

      expect(stderr).to have_output "#{C_GREY}echo 1#{C_RESET}\n"
      expect(stdout).to have_output "1\n"
    end

    it 'removes unnecessary double quotes' do
      run 'echodo echo "1"'

      expect(stderr).to have_output "#{C_GREY}echo 1#{C_RESET}\n"
      expect(stdout).to have_output "1\n"
    end

    it 'retains quoted empty double quoted strings' do
      run 'echodo echo ""'

      expect(stderr).to have_output "#{C_GREY}echo ''#{C_RESET}\n"
      expect(stdout).to have_output "\n"
    end

    it 'retains quoted empty single quoted strings' do
      run "echodo echo ''"

      expect(stderr).to have_output "#{C_GREY}echo ''#{C_RESET}\n"
      expect(stdout).to have_output "\n"
    end

    it 'uses single quotes to escape spaces when given a single quoted string' do
      run "echodo echo '1 and 2'"

      expect(stderr).to have_output "#{C_GREY}echo '1 and 2'#{C_RESET}\n"
      expect(stdout).to have_output "1 and 2\n"
    end

    it 'uses single quotes to escape spaces when given a double quoted string' do
      run 'echodo echo "1 and 2"'

      expect(stderr).to have_output "#{C_GREY}echo '1 and 2'#{C_RESET}\n"
      expect(stdout).to have_output "1 and 2\n"
    end

    it 'uses single quotes to escape spaces when given a double quoted string' do
      run 'echodo echo "1 and 2"'

      expect(stderr).to have_output "#{C_GREY}echo '1 and 2'#{C_RESET}\n"
      expect(stdout).to have_output "1 and 2\n"
    end

    it 'uses single quotes to escape spaces when given a backslash escaped string' do
      run "echodo echo 1\\ and\\ 2"

      expect(stderr).to have_output "#{C_GREY}echo '1 and 2'#{C_RESET}\n"
      expect(stdout).to have_output "1 and 2\n"
    end

    it 'uses single quotes to escape \\(whatever\\)' do
      run "echodo echo \\(whatever\\)"
      expect(stderr).to have_output "#{C_GREY}echo '(whatever)'#{C_RESET}\n"
      expect(stdout).to have_output "(whatever)\n"
    end

    it "uses single quotes to escape '(whatever)'" do
      run "echodo echo '(whatever)'"
      expect(stderr).to have_output "#{C_GREY}echo '(whatever)'#{C_RESET}\n"
      expect(stdout).to have_output "(whatever)\n"
    end

    it "uses single quotes to escape '[whatever]" do
      run "echodo echo '[whatever]'"
      expect(stderr).to have_output "#{C_GREY}echo '[whatever]'#{C_RESET}\n"
      expect(stdout).to have_output "[whatever]\n"
    end

    it "uses single quotes to escape 'what)ever]'" do
      run "echodo echo 'what)ever]'"
      expect(stderr).to have_output "#{C_GREY}echo 'what)ever]'#{C_RESET}\n"
      expect(stdout).to have_output "what)ever]\n"
    end

    it "uses single quotes to escape 'what) ever]'" do
      run "echodo echo 'what) ever]'"
      expect(stderr).to have_output "#{C_GREY}echo 'what) ever]'#{C_RESET}\n"
      expect(stdout).to have_output "what) ever]\n"
    end

    it "uses single quotes to escape 'what)ever'" do
      run "echodo echo 'what)ever'"
      expect(stderr).to have_output "#{C_GREY}echo 'what)ever'#{C_RESET}\n"
      expect(stdout).to have_output "what)ever\n"
    end

    it "uses single quotes to escape 'what>ever'" do
      run "echodo echo 'what>ever'"
      expect(stderr).to have_output "#{C_GREY}echo 'what>ever'#{C_RESET}\n"
      expect(stdout).to have_output "what>ever\n"
    end

    it "uses single quotes to escape 'what<ever'" do
      run "echodo echo 'what<ever'"
      expect(stderr).to have_output "#{C_GREY}echo 'what<ever'#{C_RESET}\n"
      expect(stdout).to have_output "what<ever\n"
    end

    it "uses single quotes to escape 'what\\n\\never'" do
      run "echodo echo 'what\n\never'"
      expect(stderr).to have_output "#{C_GREY}echo 'what\n\never'#{C_RESET}\n"
      expect(stdout).to have_output "what\n\never\n"
    end

    it "uses single quotes to escape '$dance'" do
      run "echodo echo '$dance'"
      expect(stderr).to have_output "#{C_GREY}echo '$dance'#{C_RESET}\n"
      expect(stdout).to have_output "$dance\n"
    end

    it %{uses single quotes to escape '"$dance"'} do
      run %{echodo echo '"$dance"'}
      expect(stderr).to have_output %{#{C_GREY}echo '"$dance"'#{C_RESET}\n}
      expect(stdout).to have_output %{"$dance"\n}
    end

    it "uses double quotes to escape single quotes" do
      run "echodo echo don\\'t"
      expect(stderr).to have_output %{#{C_GREY}echo "don't"#{C_RESET}\n}
      expect(stdout).to have_output "don't\n"
    end

    it "uses single quotes to escape double quotes" do
      run %{echodo echo 'do or do not there is no "try"'}
      expect(stderr).to have_output %{#{C_GREY}echo 'do or do not there is no \"try\"'#{C_RESET}\n}
      expect(stdout).to have_output %{do or do not there is no "try"\n}
    end

    it "uses double quotes to escape both types of quotes" do
      # because "\"" works and '\'' doesn't
      run %{echodo echo "do or don't "'there is no "try"'}
      expect(stderr).to have_output %{#{C_GREY}echo "do or don't there is no \\"try\\""#{C_RESET}\n}
      expect(stdout).to have_output %{do or don't there is no "try"\n}
    end

    it "doesn't escape !" do
      # I never want history expansion
      # so I `set +H` in bash_profile
      # so I don't need to escape `!`
      run %{echodo echo !}
      expect(stderr).to have_output %{#{C_GREY}echo !#{C_RESET}\n}
      expect(stdout).to have_output %{!\n}
    end
  end
end
