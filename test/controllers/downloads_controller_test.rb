require "test_helper"

class DownloadsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get downloads_index_url
    assert_response :success
  end

  test "should get download" do
    get downloads_download_url
    assert_response :success
  end
end
