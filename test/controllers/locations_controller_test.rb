# frozen_string_literal: true

require "test_helper"

class LocationsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  def setup
    login_as(test_user, scope: :user)
    @account = test_user.accounts.first
  end

  def teardown
    Warden.test_reset!
  end

  test "create with address geocodes and saves location" do
    geocoder_result = OpenStruct.new(latitude: 41.8781, longitude: -87.6298)

    Geocoder.stub(:search, [geocoder_result]) do
      assert_difference -> { @account.locations.count }, 1 do
        post account_locations_path(@account), params: {
          location: {
            name: "Chicago Office",
            address: "233 S Wacker Dr, Chicago, IL"
          }
        }
      end

      assert_response :redirect
      follow_redirect!

      location = @account.locations.order(:created_at).last
      assert_equal "Chicago Office", location.name
      assert_in_delta 41.8781, location.latitude.to_f, 0.001
      assert_in_delta(-87.6298, location.longitude.to_f, 0.001)
      assert location.time_zone.present?
    end
  end

  test "create shows error when geocoding fails" do
    Geocoder.stub(:search, []) do
      post account_locations_path(@account), params: {
        location: {
          name: "Nowhere",
          address: "asdfghjkl"
        }
      }

      assert_response :redirect
      assert_includes flash[:alert], "Could not find that address"
    end
  end

  test "create shows validation errors when location is invalid" do
    geocoder_result = OpenStruct.new(latitude: 41.8781, longitude: -87.6298)

    Geocoder.stub(:search, [geocoder_result]) do
      post account_locations_path(@account), params: {
        location: {
          name: "",
          address: "233 S Wacker Dr, Chicago, IL"
        }
      }

      assert_response :redirect
      assert flash[:alert].present?
    end
  end

  test "time_zone_for falls back when timezone_finder raises" do
    geocoder_result = OpenStruct.new(latitude: 0.0, longitude: 0.0)

    # Stub TimezoneFinder to raise
    mock_finder = Minitest::Mock.new
    mock_finder.expect(:timezone_at, nil) { raise "boom" }

    Geocoder.stub(:search, [geocoder_result]) do
      TimezoneFinder.stub(:create, mock_finder) do
        post account_locations_path(@account), params: {
          location: {
            name: "Fallback Test",
            address: "middle of nowhere"
          }
        }
      end
    end

    assert_response :redirect
    location = @account.locations.order(:created_at).last
    assert_equal "America/Chicago", location.time_zone
  end

  test "destroy deletes location with no devices" do
    location = @account.locations.create!(name: "Empty Location", latitude: 40.0, longitude: -90.0, time_zone: "America/Chicago")

    delete account_location_path(@account, location)

    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "deleted"
    assert_nil Location.find_by(id: location.id)
  end

  test "destroy rejects deletion when devices exist" do
    location = @account.locations.create!(name: "Has Devices", latitude: 40.0, longitude: -90.0, time_zone: "America/Chicago")
    Device.create!(name: "blocker-device-#{SecureRandom.hex(4)}", model: "visionect_13", location: location)

    delete account_location_path(@account, location)

    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "Delete all devices"
    assert Location.find_by(id: location.id).present?
  end
end
