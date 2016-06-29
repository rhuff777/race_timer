require 'test_helper'

class PenaltiesControllerTest < ActionController::TestCase
  setup do
    @penalty = penalties(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:penalties)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create penalty" do
    assert_difference('Penalty.count') do
      post :create, penalty: { gates: @penalty.gates }
    end

    assert_redirected_to penalty_path(assigns(:penalty))
  end

  test "should show penalty" do
    get :show, id: @penalty
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @penalty
    assert_response :success
  end

  test "should update penalty" do
    patch :update, id: @penalty, penalty: { gates: @penalty.gates }
    assert_redirected_to penalty_path(assigns(:penalty))
  end

  test "should destroy penalty" do
    assert_difference('Penalty.count', -1) do
      delete :destroy, id: @penalty
    end

    assert_redirected_to penalties_path
  end
end
