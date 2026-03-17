require "test_helper"

class IncomesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get incomes_index_url
    assert_response :success
  end

  test "should get show" do
    get incomes_show_url
    assert_response :success
  end

  test "should get new" do
    get incomes_new_url
    assert_response :success
  end

  test "should get create" do
    get incomes_create_url
    assert_response :success
  end

  test "should get edit" do
    get incomes_edit_url
    assert_response :success
  end

  test "should get update" do
    get incomes_update_url
    assert_response :success
  end

  test "should get destroy" do
    get incomes_destroy_url
    assert_response :success
  end
end
