class SkiService
  def self.call(user)
    response = HTTParty.get("https://skiapp.onthesnow.com/app/widgets/resortlist?region=us&regionids=251&language=en&pagetype=skireport&direction=-1&order=stop&limit=50&offset=0&countrycode=USA&minvalue=-1&open=open")

    if response.key?("rows")
      resorts_i_care_about =
        response["rows"].
          select { |r| [20, 36, 77, 197, 482].include?(r["_id"]) }.
          sort { |r| r["resort_name_short"] }

      reports = resorts_i_care_about.map do |r|
        runs =
          if r["snowcone"]["num_trails_slopes_open"] == r["resortProfile"]["number_runs"]
            ""
          else
            "#{((r["snowcone"]["num_trails_slopes_open"]/r["resortProfile"]["number_runs"].to_f).ceil)}%"
          end

        {
          name: r["resort_name_short"],
          runs: runs,
          snow_24: "#{r["pastSnow"]["snow0day"]}\"",
          snow_72: "#{r["pastSnow"]["sum3"]}\"",
          snow_base: (r["snowcone"]["base_depth_cm"] / 2.54).round
        }
      end

      user.update(ski_reports: reports)
    else
      user.update(ski_reports: [], error_messages: user.error_messages << "Could not load ski resort data.")
    end
  rescue => e
    user.update(error_messages: user.error_messages << e.message)
  end
end
