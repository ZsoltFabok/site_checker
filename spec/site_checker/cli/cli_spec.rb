require 'spec_helper'
require 'site_checker/cli/cli_spec_helper'

describe "CLI" do
  include CliSpecHelper

  before(:each) do
    @command = File.expand_path('../../../bin/site_checker', File.dirname(__FILE__))
    clean_fs_test_path
  end

  context "argument check" do
    it "help option should print a description and the list of available options" do
      description = "Visits the <site_url> and prints out the list of those URLs which cannot be found\n\n"
      output = exec(@command, "-h")
      output2 = exec(@command, "--help")
      expect(output).to eql(output2)
      expect(output).to eql(description + option_list)
    end

    it "version option should print the current version" do
      output = exec(@command, "-v")
      output2 = exec(@command, "--version")
      expect(output).to eql(output2)
      expect(output).to eql(SiteChecker::VERSION + "\n")
    end

    it "missing number after the max-recursion-depth option should print error and the list of available options" do
      message = "Error: missing argument: --max-recursion-depth\n\n"
      output = exec(@command, "--max-recursion-depth")
      expect(output).to eql(message + option_list)
    end

    it "missing site_url should print error message" do
      message = "Error: missing argument: <site_url>\n\n"
      output = exec(@command, "")
      expect(output).to eql(message + option_list)
    end
  end

  context "execution" do
    it "should run a basic check without any problem" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      filesystemmock("index.html", content)
      filesystemmock("/one-level-down/index.html", content)

      expected = "Collected local pages:\n  /one-level-down\n  test_data_public"

      output = exec(@command, "--print-local-pages #{fs_test_path}")
      expect(output).to eql(expected)
    end

    it "should print out the collected problems" do
      content = "<html>text<a href=\"/one-level-down\"/></html>"
      filesystemmock("index.html", content)
      filesystemmock("/two-levels-down/index.html", content)

      expected = "Collected problems:\n  test_data_public\n    /one-level-down (404 Not Found)"

      output = exec(@command, "#{fs_test_path}")
      expect(output).to eql(expected)
    end

    it "should ignore all the provided URLs" do
      content = "<html>text<a href=\"/one-level-down\"/><a href=\"/two-levels-down\"/></html>"
      filesystemmock("index.html", content)

      expected = "Collected local pages:\n  test_data_public"

      output = exec(@command, "--print-local-pages --ignore /one-level-down --ignore /two-levels-down #{fs_test_path}")
      expect(output).to eql(expected)
    end
  end
end