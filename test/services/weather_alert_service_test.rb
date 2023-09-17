# frozen_string_literal: true

require "test_helper"

class WeatherAlertTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch_does_not_error
    VCR.use_cassette("WeatherAlert.fetch") do
      WeatherAlert.fetch
    end
  end

  def test_calendar_event_does_not_error
    data = {
      "response"=>
      {"type"=>"FeatureCollection",
       "title"=>
        "Current watches, warnings, and advisories for North Douglas County Below 6000 Feet/Denver/West Adams and Arapahoe Counties/East Broomfield County (COZ040) CO",
       "updated"=>"2023-09-03T20:03:34+00:00",
       "@context"=>
        ["https://geojson.org/geojson-ld/geojson-context.jsonld",
         {"wx"=>"https://api.weather.gov/ontology#",
          "@vocab"=>"https://api.weather.gov/ontology#",
          "@version"=>"1.1"}],
       "features"=>
        [{"id"=>
           "https://api.weather.gov/alerts/urn:oid:2.49.0.1.840.0.0fe6c1e5724eecc73c914e9363060385a5d0c6ed.001.1",
          "type"=>"Feature",
          "geometry"=>
           {"type"=>"Polygon",
            "coordinates"=>
             [[[-105.08, 39.67],
               [-105.05, 39.67],
               [-105.06, 39.68],
               [-104.75, 39.78],
               [-104.44, 39.28],
               [-104.77, 39.13],
               [-105.08, 39.67]]]},
          "properties"=>
           {"id"=>"urn:oid:2.49.0.1.840.0.0fe6c1e5724eecc73c914e9363060385a5d0c6ed.001.1",
            "@id"=>
             "https://api.weather.gov/alerts/urn:oid:2.49.0.1.840.0.0fe6c1e5724eecc73c914e9363060385a5d0c6ed.001.1",
            "ends"=>nil,
            "sent"=>"2023-09-03T14:03:00-06:00",
            "@type"=>"wx:Alert",
            "event"=>"Special Weather Statement",
            "onset"=>"2023-09-03T14:03:00-06:00",
            "sender"=>"w-nws.webmaster@noaa.gov",
            "status"=>"Actual",
            "expires"=>"2023-09-03T14:30:00-06:00",
            "geocode"=>
             {"UGC"=>["COZ040", "COZ041"],
              "SAME"=>["008001", "008005", "008014", "008031", "008035", "008039"]},
            "urgency"=>"Expected",
            "areaDesc"=>
             "North Douglas County Below 6000 Feet/Denver/West Adams and Arapahoe Counties/East Broomfield County; Elbert/Central and East Douglas Counties Above 6000 Feet",
            "category"=>"Met",
            "headline"=>"Special Weather Statement issued September 3 at 2:03PM MDT by NWS Denver CO",
            "response"=>"Execute",
            "severity"=>"Moderate",
            "certainty"=>"Observed",
            "effective"=>"2023-09-03T14:03:00-06:00",
            "parameters"=>
             {"EAS-ORG"=>["WXR"],
              "NWSheadline"=>
               ["Strong thunderstorms will impact portions of eastern Douglas, northwestern Elbert, western Arapahoe and southwestern Denver Counties through 230 PM MDT"],
              "maxHailSize"=>["0.50"],
              "maxWindGust"=>["50 MPH"],
              "BLOCKCHANNEL"=>["EAS", "NWEM", "CMAS"],
              "WMOidentifier"=>["WWUS85 KBOU 032003"],
              "AWIPSidentifier"=>["SPSBOU"],
              "eventMotionDescription"=>
               ["2023-09-03T20:03:00-00:00...storm...225DEG...29KT...39.67,-105.05 39.19,-104.74"]},
            "references"=>[],
            "senderName"=>"NWS Denver CO",
            "description"=>
             "At 203 PM MDT, Doppler radar was tracking strong thunderstorms along\na line extending from Denver to 5 miles east of Greenland, or along a\nline extending from 54 miles south of Greeley to 22 miles north of\nColorado Springs. Movement was northeast at 35 mph.\n\nHAZARD...Wind gusts up to 50 mph and half inch hail.\n\nSOURCE...Radar indicated.\n\nIMPACT...Gusty winds could knock down tree limbs and blow around\nunsecured objects. Minor damage to outdoor objects is\npossible.\n\nLocations impacted include...\nDenver, southwestern Aurora, Centennial, Highlands Ranch, Castle\nRock, Parker, Littleton, Englewood, Greenwood Village, Lone Tree,\nSheridan, Elizabeth, The Pinery, Arapahoe Park, Franktown, Ponderosa\nPark, Castle Pines, Buckley SFB, and Sedalia.",
            "instruction"=>
             "Prepare for sudden gusty winds. Secure loose objects and move to a\nsafe shelter inside a building or vehicle.\n\nIf outdoors, consider seeking shelter inside a building.",
            "messageType"=>"Alert",
            "affectedZones"=>
             ["https://api.weather.gov/zones/forecast/COZ040",
              "https://api.weather.gov/zones/forecast/COZ041"]}}]},
     "last_fetched_at"=>"2023-09-03 14:23:44 -0600"
    }

    WeatherAlert.stub :load, data do
      event = WeatherAlert.calendar_event

      assert(event.to_h[:summary].include?("Strong thunderstorms"))
    end
  end
end