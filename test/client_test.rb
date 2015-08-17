require "blade_runner"
require "blade_runner/test_helper"
require "webmock/minitest"

class ClientTest < BladeRunner::TestCase
  setup do
    WebMock.disable_net_connect!

    stub_request(:get, "https://saucelabs.com/rest/v1/info/platforms/webdriver")
      .to_return(body: File.new("test/fixtures/sauce_webdrivers.json"))
  end

  test "platforms for browser" do
    assert_platforms ["Mac 10.9", "chrome", "44"], name: "Google Chrome"
  end

  test "platforms for browser using name that matches" do
    assert_platforms ["Mac 10.9", "chrome", "44"], name: "Chrome"
  end

  test "platforms for browser on one operating system" do
    assert_platforms ["Mac 10.9", "chrome", "44"], name: "Google Chrome", os: "Mac"
    assert_platforms ["Mac 10.9", "chrome", "44"], name: "Google Chrome", os: ["Mac"]
  end

  test "platforms for browser on multiple operating systems" do
    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Windows 10", "chrome", "44"]
      ], name: "Google Chrome", os: ["Mac", "Windows"]
  end

  test "platforms for browser with version" do
    assert_platforms ["Mac 10.9", "chrome", "43"], name: "Google Chrome", version: 43
  end

  test "platforms for browser with multiple versions" do
    assert_platforms [
        ["Mac 10.9", "chrome", "41"],
        ["Mac 10.9", "chrome", "40"]
      ], name: "Google Chrome", version: [ 41, 40 ]
  end

  test "platforms for browser with latest versions" do
    assert_platforms ["Mac 10.9", "chrome", "44"], name: "Google Chrome", latest_versions: 1

    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Mac 10.9", "chrome", "43"]
      ], name: "Google Chrome", latest_versions: 2

    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Mac 10.9", "chrome", "43"],
        ["Mac 10.9", "chrome", "42"]
      ], name: "Google Chrome", latest_versions: 3
  end

  test "platforms for browser on multiple operating systems with version" do
    assert_platforms [
        ["Mac 10.9", "chrome", "43"],
        ["Windows 10", "chrome", "43"]
      ], name: "Google Chrome", os: ["Mac", "Windows"], version: 43
  end

  test "platforms for browser on multiple operating systems with multiple versions" do
    assert_platforms [
        ["Mac 10.9", "chrome", "39"],
        ["Mac 10.9", "chrome", "38"],
        ["Windows 10", "chrome", "39"],
        ["Windows 10", "chrome", "38"]
      ], name: "Google Chrome", os: ["Mac", "Windows"], version: [39, 38]
  end

  test "platforms for browser on multiple operating systems with latest versions" do
    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Mac 10.9", "chrome", "43"],
        ["Windows 10", "chrome", "44"],
        ["Windows 10", "chrome", "43"]
      ], name: "Google Chrome", os: ["Mac", "Windows"], latest_versions: 2
  end

  private
    def assert_platforms(platforms, browsers)
      initialize_with_browsers Array.wrap(browsers)
      platforms = [platforms] unless platforms.first.is_a?(Array)
      assert_equal platforms, client.platforms
    end

    def client
      BladeRunner::SauceLabsPlugin::Client
    end

    def initialize_with_browsers(browsers)
      BladeRunner.initialize! plugins: { sauce_labs: { browsers: browsers } }
    end
end
