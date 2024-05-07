# frozen_string_literal: true

require "test_helper"

class BirdnetApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:birdnet_fetch, match_requests_on: [:method]) do
      BirdnetApi.fetch
    end
  end

  def test_health_no_data
    BirdnetApi.stub :last_fetched_at, nil do
      assert(!BirdnetApi.healthy?)
    end
  end

  def test_health_current_data
    BirdnetApi.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(BirdnetApi.healthy?)
      end
    end
  end

  def test_health_stale_data
    BirdnetApi.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(BirdnetApi.healthy?)
      end
    end
  end

  def test_most_unusual_species_trailing_24h_no_data
    BirdnetApi.stub :data, {} do
      assert_equal(BirdnetApi.most_unusual_species_trailing_24h, {})
    end
  end

  def test_most_unusual_species_trailing_24h
    data = {"species" => [{"id" => 134,
                           "commonName" => "House Finch",
                           "scientificName" => "Haemorhous mexicanus",
                           "color" => "#ff5a86",
                           "imageUrl" =>
     "https://media.birdweather.com/species/134/HouseFinch-standard-3329463dada4a864431241d37400ba54.jpg",
                           "thumbnailUrl" =>
     "https://media.birdweather.com/species/134/HouseFinch-thumbnail-ea7d4c693d0ac395d440407b51951f22.jpg",
                           "detections" => {"total" => 103, "almostCertain" => 103, "veryLikely" => 0, "uncertain" => 0, "unlikely" => 0},
                           "latestDetectionAt" => "2024-04-13T19:16:35.000-06:00"},
      {"id" => 28,
       "commonName" => "Townsend's Solitaire",
       "scientificName" => "Myadestes townsendi",
       "color" => "#00a842",
       "imageUrl" =>
        "https://media.birdweather.com/species/28/TownsendsSolitaire-standard-d37b6e043b4eed13817adc83cd476a15.jpg",
       "thumbnailUrl" =>
        "https://media.birdweather.com/species/28/TownsendsSolitaire-thumbnail-fe60cb6923339361e1eecf90773786da.jpg",
       "detections" => {"total" => 3, "almostCertain" => 3, "veryLikely" => 0, "uncertain" => 0, "unlikely" => 0},
       "latestDetectionAt" => "2024-04-13T18:51:02.000-06:00"},
      {"id" => 60,
       "commonName" => "Rock Pigeon",
       "scientificName" => "Columba livia",
       "color" => "#8ed96e",
       "imageUrl" =>
        "https://media.birdweather.com/species/60/RockPigeon-standard-e442656b8173c4956bc4ef5fdd1a7e53.jpg",
       "thumbnailUrl" =>
        "https://media.birdweather.com/species/60/RockPigeon-thumbnail-a43e71081b432231e10a1774b5735053.jpg",
       "detections" => {"total" => 3, "almostCertain" => 3, "veryLikely" => 0, "uncertain" => 0, "unlikely" => 0},
       "latestDetectionAt" => "2024-04-13T20:09:35.000-06:00"},
      {"id" => 65,
       "commonName" => "Northern Flicker",
       "scientificName" => "Colaptes auratus",
       "color" => "#ff6ad7",
       "imageUrl" =>
        "https://media.birdweather.com/species/65/NorthernFlicker-standard-981bd7e4c13509e1db15ba936807ddb4.jpg",
       "thumbnailUrl" =>
        "https://media.birdweather.com/species/65/NorthernFlicker-thumbnail-7e0c055da080666c647db31e799f9ed9.jpg",
       "detections" => {"total" => 2, "almostCertain" => 2, "veryLikely" => 0, "uncertain" => 0, "unlikely" => 0},
       "latestDetectionAt" => "2024-04-13T18:33:17.000-06:00"},
      {"id" => 568,
       "commonName" => "Western Meadowlark",
       "scientificName" => "Sturnella neglecta",
       "color" => "#8c9e00",
       "imageUrl" =>
        "https://media.birdweather.com/species/568/WesternMeadowlark-standard-cf1c86d78827eccc53bb0337bdacca0c.jpg",
       "thumbnailUrl" =>
        "https://media.birdweather.com/species/568/WesternMeadowlark-thumbnail-c0f44fda850bcdd76811e2761c64c4b9.jpg",
       "detections" => {"total" => 2, "almostCertain" => 2, "veryLikely" => 0, "uncertain" => 0, "unlikely" => 0},
       "latestDetectionAt" => "2024-04-13T16:10:08.000-06:00"}]}

    BirdnetApi.stub :data, data do
      assert_equal(568, BirdnetApi.most_unusual_species_trailing_24h["id"])
    end
  end
end
