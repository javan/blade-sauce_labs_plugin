require "test_helper"
require "webmock/minitest"

class ClientTest < TestCase
  setup do
    WebMock.disable_net_connect!

    stub_request(:get, "https://saucelabs.com/rest/v1/info/platforms/webdriver")
      .to_return(body: File.new("test/fixtures/sauce_webdrivers.json"))
  end

  test "platforms for browser" do
    assert_platforms ["Mac 10.9", "chrome", "44"], "Google Chrome": { version: 44 }
    assert_platforms ["Mac 10.9", "chrome", "44"], "Google Chrome": 44
    assert_platforms ["Mac 10.9", "chrome", "44"], "Google Chrome": nil
    assert_platforms ["Mac 10.9", "chrome", "44"], "Google Chrome": ""
    assert_platforms ["Mac 10.9", "chrome", "44"], "Google Chrome": true
  end

  test "platforms for browser using name that matches" do
    assert_platforms ["Mac 10.9", "chrome", "44"], chrome: 44
  end

  test "platforms for browser using name alias" do
    assert_platforms ["Windows 10", "internet explorer", "11"], IE: 11
    assert_platforms ["Windows 10", "internet explorer", "11"], ie: 11
  end

  test "platforms for browser on one operating system" do
    assert_platforms ["Mac 10.9", "chrome", "44"], chrome: { os: "Mac" }
    assert_platforms ["Mac 10.9", "chrome", "44"], chrome: { os: ["Mac"] }
  end

  test "platforms for browser on multiple operating systems" do
    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Windows 10", "chrome", "44"]
      ], chrome: { os: ["Mac", "Windows"] }

    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Windows 10", "chrome", "44"]
      ], chrome: { os: "Mac, Windows" }
  end

  test "platforms for browser with version" do
    assert_platforms ["Mac 10.9", "chrome", "43"], chrome: 43
  end

  test "platforms for browser with non-numeric version" do
    assert_platforms ["Mac 10.9", "chrome", "dev"], chrome: "dev"
    assert_platforms ["Mac 10.9", "chrome", "beta"], chrome: { version: "beta" }
  end

  test "platforms for browser with multiple versions" do
    assert_platforms [
        ["Mac 10.9", "chrome", "41"],
        ["Mac 10.9", "chrome", "40"]
      ], chrome: { version: [ 41, 40 ] }
  end

  test "platforms for browser with latest versions" do
    assert_platforms ["Mac 10.9", "chrome", "44"], chrome: { version: -1 }
    assert_platforms ["Mac 10.9", "chrome", "44"], chrome: -1

    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Mac 10.9", "chrome", "43"]
      ], chrome: -2

    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Mac 10.9", "chrome", "43"],
        ["Mac 10.9", "chrome", "42"]
      ], chrome: -3
  end

  test "platforms for browser on multiple operating systems with version" do
    assert_platforms [
        ["Mac 10.9", "chrome", "43"],
        ["Windows 10", "chrome", "43"]
      ], chrome: { os: ["Mac", "Windows"], version: 43 }
  end

  test "platforms for browser on multiple operating systems with multiple versions" do
    assert_platforms [
        ["Mac 10.9", "chrome", "39"],
        ["Mac 10.9", "chrome", "38"],
        ["Windows 10", "chrome", "39"],
        ["Windows 10", "chrome", "38"]
      ], chrome: { os: ["Mac", "Windows"], version: [39, 38] }
  end

  test "platforms for browser on multiple operating systems with latest versions" do
    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Mac 10.9", "chrome", "43"],
        ["Windows 10", "chrome", "44"],
        ["Windows 10", "chrome", "43"]
      ], chrome: { os: ["Mac", "Windows"], version: -2 }
  end


  test "platforms for browser on multiple operating systems with latest versions that aren't identical" do
    # When Sauce Labs has a newer version of a browser for one OS
    assert_platforms [
        ["Mac 10.9", "chrome", "44"],
        ["Mac 10.9", "chrome", "43"],
        ["Linux", "chrome", "43"],
        ["Linux", "chrome", "42"]
      ], chrome: { os: ["Mac", "Linux"], version: -2 }
  end

  private
    def assert_platforms(platforms, browsers)
      initialize_with_browsers browsers
      platforms = [platforms] unless platforms.first.is_a?(Array)
      platforms.map! { |p| { platform: p[0], browserName: p[1], version: p[2] } }
      assert_equal platforms, client.platforms
    end

    def client
      Blade::SauceLabsPlugin::Client
    end

    def initialize_with_browsers(browsers)
      Blade.initialize!
      Blade.config.plugins.sauce_labs = { browsers: browsers }
    end
end
