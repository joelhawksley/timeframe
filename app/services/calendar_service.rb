class CalendarService
  def self.call(user)
    user.update(calendar_events: new.fetch_calendar_events(user))
  end

  def fetch_calendar_events(user)
    calendar_events(user)
  end

  private

  def calendar_events(user)
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
    })

    client.update!(user.google_authorization)

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    begin
      events = []

      service.list_calendar_lists.items.each_with_index do |calendar, index|
        service.list_events(calendar.id, max_results: 100, single_events: true, order_by: 'startTime', time_min: (DateTime.now - 2.weeks).iso8601).items.each_with_index do |event, index_2|
          event_json = event.as_json

          start_i =
            if event_json["start"].key?("date")
              ActiveSupport::TimeZone["America/Denver"].parse(event_json["start"]["date"]).utc.to_i
            else
              ActiveSupport::TimeZone["America/Denver"].parse(event_json["start"]["date_time"]).utc.to_i
            end

          end_i =
            if event_json["end"].key?("date")
              # Subtract 1 second, as Google gives us the end date as the following day, not the end of the current day
              ActiveSupport::TimeZone["America/Denver"].parse(event_json["end"]["date"]).utc.to_i - 1
            else
              ActiveSupport::TimeZone["America/Denver"].parse(event_json["end"]["date_time"]).utc.to_i
            end

          events << event_json.slice(
              "start",
              "end",
              "summary"
            ).merge(
              calendar: calendar.summary,
              icon: icon_for_title("#{calendar.summary} #{event_json["summary"]}"),
              start_i: start_i,
              end_i: end_i,
              all_day: event_json["start"].key?("date")
            ).symbolize_keys!
        end
      end

      events.sort_by { |event| event[:start_i] }
    rescue Google::Apis::AuthorizationError => exception
      response = client.refresh!

      user.update(google_authorization: user.google_authorization.merge(response))

      retry
    end
  end

  def icon_for_title(title)
    out = ''

    ICON_MATCHES.to_a.each do |icon, regex|
      if eval("#{regex}i") =~ title
        out = icon
        break
      end
    end

    out
  end

  ICON_MATCHES = {
    "run" => "/((\d{1,2}mi)|Crosstrain|Marathon)/",
    "cutlery" => "/(dinner|restaurant|supper|cake|cutlery)/",
    "calendar" => "/(holiday|calendar)/",
    "tree" => "/(hike|boulder valley ranch)/",
    "home" => "/(home|apartment|house)/",
    "gavel" => "/(docket|jd|aitc)/",
    "heartbeat" => "/(gym|heartbeat)/",
    "plane" => "/(flight)/",
    "truck" => "/(UPS)/",
    "book" => "/(library)/",
    "sun-o" => "/(wunder)/",
    "paw" => "/(captain|dog|dog park)/",
    "car" => "/(pick up|drive|driving)/",
    "shopping-bag" => "/(shop|shopping|clothes|pearl street)/",
    "shopping-cart" => "/(groceries|trader|sooper)/",
    "group" => "/(with)/",
    "500px" => "/(500px)/",
    "address-book" => "/(address-book)/",
    "address-card" => "/(address-card)/",
    "adjust" => "/(adjust)/",
    "align-center" => "/(align-center)/",
    "align-justify" => "/(align-justify)/",
    "align-left" => "/(align-left)/",
    "align-right" => "/(align-right)/",
    "amazon" => "/(amazon)/",
    "ambulance" => "/(ambulance)/",
    "american-sign-language-interpreting" => "/(american-sign-language-interpreting)/",
    "anchor" => "/(anchor)/",
    "android" => "/(android)/",
    "angellist" => "/(angellist)/",
    "archive" => "/(archive)/",
    "area-chart" => "/(area-chart)/",
    "arrow-down" => "/(down)/",
    "arrow-left" => "/(left)/",
    "arrow-right" => "/(right)/",
    "arrow-up" => "/(up)/",
    "arrows" => "/(arrows)/",
    "arrows-alt" => "/(arrows-alt)/",
    "arrows-h" => "/(arrows-h)/",
    "arrows-v" => "/(arrows-v)/",
    "asl-interpreting" => "/(asl-interpreting)/",
    "assistive-listening-systems" => "/(assistive-listening-systems)/",
    "asterisk" => "/(asterisk)/",
    "audio-description" => "/(audio-description)/",
    "automobile" => "/(automobile)/",
    "backward" => "/(backward)/",
    "balance-scale" => "/(balance-scale)/",
    "bandcamp" => "/(bandcamp)/",
    "bar-chart" => "/(bar-chart)/",
    "barcode" => "/(barcode)/",
    "bathtub" => "/(bathtub)/",
    "battery" => "/(battery)/",
    "battery-0" => "/(battery-0)/",
    "battery-1" => "/(battery-1)/",
    "battery-2" => "/(battery-2)/",
    "battery-3" => "/(battery-3)/",
    "battery-4" => "/(battery-4)/",
    "battery-empty" => "/(battery-empty)/",
    "battery-full" => "/(battery-full)/",
    "battery-half" => "/(battery-half)/",
    "battery-quarter" => "/(battery-quarter)/",
    "battery-three-quarters" => "/(battery-three-quarters)/",
    "behance" => "/(behance)/",
    "behance-square" => "/(behance-square)/",
    "bell-o" => "/(bell-)/",
    "bicycle" => "/(bicycle)/",
    "binoculars" => "/(binoculars)/",
    "bitbucket" => "/(bitbucket)/",
    "bitbucket-square" => "/(bitbucket-square)/",
    "bitcoin" => "/(bitcoin)/",
    "black-tie" => "/(black-tie)/",
    "bluetooth" => "/(bluetooth)/",
    "bluetooth-b" => "/(bluetooth-b)/",
    "bookmark" => "/(bookmark)/",
    "braille" => "/(braille)/",
    "briefcase" => "/(briefcase)/",
    "building" => "/(building)/",
    "bullhorn" => "/(bullhorn)/",
    "bullseye" => "/(bullseye)/",
    "buysellads" => "/(buysellads)/",
    "calculator" => "/(calculator)/",
    "calendar-o" => "/(calendar)/",
    "camera" => "/(camera)/",
    "camera-retro" => "/(camera-retro)/",
    "caret-down" => "/(caret-down)/",
    "caret-left" => "/(caret-left)/",
    "caret-right" => "/(caret-right)/",
    "caret-up" => "/(caret-up)/",
    "cart-arrow-down" => "/(cart-arrow-down)/",
    "cart-plus" => "/(cart-plus)/",
    "cc-amex" => "/(cc-amex)/",
    "cc-diners-club" => "/(cc-diners-club)/",
    "cc-discover" => "/(cc-discover)/",
    "cc-jcb" => "/(cc-jcb)/",
    "cc-mastercard" => "/(cc-mastercard)/",
    "cc-paypal" => "/(cc-paypal)/",
    "cc-stripe" => "/(cc-stripe)/",
    "cc-visa" => "/(cc-visa)/",
    "certificate" => "/(certificate)/",
    "chain-broken" => "/(chain-broken)/",
    "chevron-circle-down" => "/(chevron-circle-down)/",
    "chevron-circle-left" => "/(chevron-circle-left)/",
    "chevron-circle-right" => "/(chevron-circle-right)/",
    "chevron-circle-up" => "/(chevron-circle-up)/",
    "chevron-down" => "/(chevron-down)/",
    "chevron-left" => "/(chevron-left)/",
    "chevron-right" => "/(chevron-right)/",
    "chevron-up" => "/(chevron-up)/",
    "chrome" => "/(chrome)/",
    "circle" => "/(circle)/",
    "circle-thin" => "/(circle-thin)/",
    "clipboard" => "/(clipboard)/",
    "clock-o" => "/(clock)/",
    "cloud-download" => "/(cloud-download)/",
    "cloud-upload" => "/(cloud-upload)/",
    "code-fork" => "/(code-fork)/",
    "codepen" => "/(codepen)/",
    "codiepie" => "/(codiepie)/",
    "coffee" => "/(coffee)/",
    "columns" => "/(columns)/",
    "comment" => "/(comment)/",
    "commenting" => "/(commenting)/",
    "comments" => "/(comments)/",
    "compass" => "/(compass)/",
    "compress" => "/(compress)/",
    "connectdevelop" => "/(connectdevelop)/",
    "contao" => "/(contao)/",
    "copyright" => "/(copyright)/",
    "creative-commons" => "/(creative-commons)/",
    "credit-card" => "/(credit-card)/",
    "credit-card-alt" => "/(credit-card-alt)/",
    "crosshairs" => "/(crosshairs)/",
    "dashboard" => "/(dashboard)/",
    "dashcube" => "/(dashcube)/",
    "database" => "/(database)/",
    "deafness" => "/(deafness)/",
    "dedent" => "/(dedent)/",
    "delicious" => "/(delicious)/",
    "desktop" => "/(desktop)/",
    "deviantart" => "/(deviantart)/",
    "diamond" => "/(diamond)/",
    "dollar" => "/(dollar)/",
    "download" => "/(download)/",
    "dribbble" => "/(dribbble)/",
    "drivers-license" => "/(drivers|license)/",
    "dropbox" => "/(dropbox)/",
    "drupal" => "/(drupal)/",
    "eercast" => "/(eercast)/",
    "ellipsis-h" => "/(ellipsis-h)/",
    "ellipsis-v" => "/(ellipsis-v)/",
    "empire" => "/(empire)/",
    "envelope" => "/(envelope)/",
    "envelope-open" => "/(envelope-open)/",
    "envelope-square" => "/(envelope-square)/",
    "envira" => "/(envira)/",
    "eraser" => "/(eraser)/",
    "exchange" => "/(exchange)/",
    "exclamation" => "/(exclamation)/",
    "exclamation-circle" => "/(exclamation-circle)/",
    "exclamation-triangle" => "/(exclamation-triangle)/",
    "expand" => "/(expand)/",
    "expeditedssl" => "/(expeditedssl)/",
    "external-link" => "/(external-link)/",
    "external-link-square" => "/(external-link-square)/",
    "eye-slash" => "/(eye-slash)/",
    "eyedropper" => "/(eyedropper)/",
    "facebook-f" => "/(facebook)/",
    "facebook-square" => "/(facebook-square)/",
    "fast-backward" => "/(fast-backward)/",
    "fast-forward" => "/(fast-forward)/",
    "fighter-jet" => "/(fighter-jet)/",
    "file-archive-o" => "/(archive)/",
    "file-audio-o" => "/(audio)/",
    "file-code-o" => "/(code)/",
    "file-excel-o" => "/(excel)/",
    "file-image-o" => "/(image)/",
    "file-movie-o" => "/(movie)/",
    "file-" => "/(file)/",
    "file-pdf-o" => "/(pdf)/",
    "file-photo-o" => "/(photo)/",
    "file-picture-o" => "/(picture)/",
    "file-powerpoint-o" => "/(powerpoint)/",
    "file-sound-o" => "/(sound)/",
    "file-text" => "/(file-text)/",
    "file-text-o" => "/(text)/",
    "file-video-o" => "/(video)/",
    "file-word-o" => "/(word)/",
    "file-zip-o" => "/(zip)/",
    "files-o" => "/(files)/",
    "filter" => "/(filter)/",
    "fire-extinguisher" => "/(fire-extinguisher)/",
    "firefox" => "/(firefox)/",
    "first-order" => "/(first-order)/",
    "flag-checkered" => "/(flag-checkered)/",
    "flag-o" => "/(flag)/",
    "flickr" => "/(flickr)/",
    "floppy-o" => "/(floppy)/",
    "folder" => "/(folder)/",
    "folder-o" => "/(folder)/",
    "fonticons" => "/(fonticons)/",
    "forumbee" => "/(forumbee)/",
    "forward" => "/(forward)/",
    "foursquare" => "/(foursquare)/",
    "frown-o" => "/(frown)/",
    "futbol-o" => "/(futbol)/",
    "gamepad" => "/(gamepad)/",
    "genderless" => "/(genderless)/",
    "get-pocket" => "/(get-pocket)/",
    "gg-circle" => "/(gg-circle)/",
    "git-square" => "/(git-square)/",
    "github" => "/(github)/",
    "github-alt" => "/(github-alt)/",
    "github-square" => "/(github-square)/",
    "gitlab" => "/(gitlab)/",
    "gittip" => "/(gittip)/",
    "glide-g" => "/(glide-g)/",
    "google" => "/(google)/",
    "graduation-cap" => "/(graduation)/",
    "hacker-news" => "/(hacker-news)/",
    "hand-grab-o" => "/(grab)/",
    "hand-paper-o" => "/(paper)/",
    "hand-peace-o" => "/(peace)/",
    "hand-pointer-o" => "/(pointer)/",
    "hand-rock-o" => "/(rock)/",
    "hand-scissors-o" => "/(scissors)/",
    "hand-spock-o" => "/(spock)/",
    "hand-stop-o" => "/(stop)/",
    "handshake-o" => "/(handshake)/",
    "hard-of-hearing" => "/(hearing)/",
    "hashtag" => "/(hashtag)/",
    "header" => "/(header)/",
    "headphones" => "/(headphones)/",
    "heart-o" => "/(heart)/",
    "history" => "/(history)/",
    "hospital-o" => "/(hospital)/",
    "hourglass" => "/(hourglass)/",
    "i-cursor" => "/(i-cursor)/",
    "id-badge" => "/(id-badge)/",
    "id-card" => "/(id-card)/",
    "indent" => "/(indent)/",
    "industry" => "/(industry)/",
    "info-circle" => "/(info-circle)/",
    "instagram" => "/(instagram)/",
    "institution" => "/(institution)/",
    "internet-explorer" => "/(internet-explorer)/",
    "intersex" => "/(intersex)/",
    "ioxhost" => "/(ioxhost)/",
    "italic" => "/(italic)/",
    "joomla" => "/(joomla)/",
    "jsfiddle" => "/(jsfiddle)/",
    "keyboard-o" => "/(keyboard)/",
    "language" => "/(language)/",
    "laptop" => "/(laptop)/",
    "lastfm" => "/(lastfm)/",
    "lastfm-square" => "/(lastfm-square)/",
    "leanpub" => "/(leanpub)/",
    "lemon-o" => "/(lemon)/",
    "level-down" => "/(level-down)/",
    "level-up" => "/(level-up)/",
    "life-bouy" => "/(life-bouy)/",
    "life-buoy" => "/(life-buoy)/",
    "life-ring" => "/(life-ring)/",
    "life-saver" => "/(life-saver)/",
    "lightbulb-o" => "/(lightbulb)/",
    "line-chart" => "/(line-chart)/",
    "linkedin" => "/(linkedin)/",
    "linkedin-square" => "/(linkedin-square)/",
    "linode" => "/(linode)/",
    "list-alt" => "/(list)/",
    "location-arrow" => "/(location)/",
    "long-arrow-down" => "/(long-arrow-down)/",
    "long-arrow-left" => "/(long-arrow-left)/",
    "long-arrow-right" => "/(long-arrow-right)/",
    "long-arrow-up" => "/(long-arrow-up)/",
    "low-vision" => "/(low-vision)/",
    "magnet" => "/(magnet)/",
    "mail-forward" => "/(mail-forward)/",
    "mail-reply" => "/(mail-reply)/",
    "mail-reply-all" => "/(mail-reply-all)/",
    "map-marker" => "/(map-marker)/",
    "map-pin" => "/(map-pin)/",
    "map-signs" => "/(map-signs)/",
    "mars-double" => "/(mars-double)/",
    "mars-stroke" => "/(mars-stroke)/",
    "mars-stroke-h" => "/(mars-stroke-h)/",
    "mars-stroke-v" => "/(mars-stroke-v)/",
    "maxcdn" => "/(maxcdn)/",
    "meanpath" => "/(meanpath)/",
    "medium" => "/(medium)/",
    "medkit" => "/(medkit)/",
    "meetup" => "/(meetup)/",
    "mercury" => "/(mercury)/",
    "microchip" => "/(microchip)/",
    "microphone" => "/(microphone)/",
    "microphone-slash" => "/(microphone-slash)/",
    "mixcloud" => "/(mixcloud)/",
    "mobile" => "/(mobile)/",
    "mobile-phone" => "/(mobile-phone)/",
    "moon-o" => "/(moon)/",
    "mortar-board" => "/(mortar-board)/",
    "motorcycle" => "/(motorcycle)/",
    "mouse-pointer" => "/(mouse-pointer)/",
    "navicon" => "/(navicon)/",
    "neuter" => "/(neuter)/",
    "newspaper-o" => "/(newspaper)/",
    "object-group" => "/(object-group)/",
    "object-ungroup" => "/(object-ungroup)/",
    "odnoklassniki" => "/(odnoklassniki)/",
    "odnoklassniki-square" => "/(odnoklassniki-square)/",
    "opencart" => "/(opencart)/",
    "openid" => "/(openid)/",
    "optin-monster" => "/(optin-monster)/",
    "outdent" => "/(outdent)/",
    "pagelines" => "/(pagelines)/",
    "paint-brush" => "/(paint-brush)/",
    "paper-plane" => "/(paper-plane)/",
    "paperclip" => "/(paperclip)/",
    "paragraph" => "/(paragraph)/",
    "pause-circle" => "/(pause-circle)/",
    "paypal" => "/(paypal)/",
    "pencil" => "/(pencil)/",
    "pencil-square" => "/(pencil-square)/",
    "percent" => "/(percent)/",
    "phone-square" => "/(phone-square)/",
    "picture-o" => "/(picture)/",
    "pie-chart" => "/(pie-chart)/",
    "pied-piper" => "/(pied-piper)/",
    "pied-piper-alt" => "/(pied-piper-alt)/",
    "pied-piper-pp" => "/(pied-piper-pp)/",
    "pinterest" => "/(pinterest)/",
    "pinterest-p" => "/(pinterest-p)/",
    "pinterest-square" => "/(pinterest-square)/",
    "play-circle" => "/(play-circle)/",
    "plus-circle" => "/(plus-circle)/",
    "plus-square" => "/(plus-square)/",
    "podcast" => "/(podcast)/",
    "power-off" => "/(power-off)/",
    "product-hunt" => "/(product-hunt)/",
    "puzzle-piece" => "/(puzzle-piece)/",
    "qrcode" => "/(qrcode)/",
    "question" => "/(question)/",
    "question-circle" => "/(question-circle)/",
    "quote-left" => "/(quote-left)/",
    "quote-right" => "/(quote-right)/",
    "random" => "/(random)/",
    "ravelry" => "/(ravelry)/",
    "recycle" => "/(recycle)/",
    "reddit" => "/(reddit)/",
    "reddit-alien" => "/(reddit-alien)/",
    "reddit-square" => "/(reddit-square)/",
    "refresh" => "/(refresh)/",
    "registered" => "/(registered)/",
    "remove" => "/(remove)/",
    "renren" => "/(renren)/",
    "reorder" => "/(reorder)/",
    "repeat" => "/(repeat)/",
    "reply-all" => "/(reply-all)/",
    "resistance" => "/(resistance)/",
    "retweet" => "/(retweet)/",
    "rocket" => "/(rocket)/",
    "rotate-left" => "/(rotate-left)/",
    "rotate-right" => "/(rotate-right)/",
    "rouble" => "/(rouble)/",
    "rss-square" => "/(rss-square)/",
    "safari" => "/(safari)/",
    "scissors" => "/(scissors)/",
    "scribd" => "/(scribd)/",
    "search" => "/(search)/",
    "search-minus" => "/(search-minus)/",
    "search-plus" => "/(search-plus)/",
    "sellsy" => "/(sellsy)/",
    "send-o" => "/(send)/",
    "server" => "/(server)/",
    "share-alt" => "/(share)/",
    "shekel" => "/(shekel)/",
    "sheqel" => "/(sheqel)/",
    "shield" => "/(shield)/",
    "shirtsinbulk" => "/(shirtsinbulk)/",
    "shopping-basket" => "/(shopping-basket)/",
    "shower" => "/(shower)/",
    "sign-in" => "/(sign-in)/",
    "sign-language" => "/(sign-language)/",
    "sign-out" => "/(sign-out)/",
    "signal" => "/(signal)/",
    "signing" => "/(signing)/",
    "simplybuilt" => "/(simplybuilt)/",
    "sitemap" => "/(sitemap)/",
    "skyatlas" => "/(skyatlas)/",
    "sliders" => "/(sliders)/",
    "slideshare" => "/(slideshare)/",
    "smile-o" => "/(smile)/",
    "snapchat" => "/(snapchat)/",
    "snapchat-ghost" => "/(snapchat-ghost)/",
    "snapchat-square" => "/(snapchat-square)/",
    "snowflake-o" => "/(snow)/",
    "soccer-ball-o" => "/(soccer)/",
    "sort-alpha-asc" => "/(sort-alpha-asc)/",
    "sort-alpha-desc" => "/(sort-alpha-desc)/",
    "sort-amount-asc" => "/(sort-amount-asc)/",
    "sort-amount-desc" => "/(sort-amount-desc)/",
    "sort-asc" => "/(sort-asc)/",
    "sort-desc" => "/(sort-desc)/",
    "sort-down" => "/(sort-down)/",
    "sort-numeric-asc" => "/(sort-numeric-asc)/",
    "sort-numeric-desc" => "/(sort-numeric-desc)/",
    "sort-up" => "/(sort-up)/",
    "soundcloud" => "/(soundcloud)/",
    "space-shuttle" => "/(space-shuttle)/",
    "spinner" => "/(spinner)/",
    "spotify" => "/(spotify)/",
    "square" => "/(square)/",
    "stack-exchange" => "/(stack-exchange)/",
    "stack-overflow" => "/(stack-overflow)/",
    "star-half" => "/(star-half)/",
    "star-half-empty" => "/(star-half-empty)/",
    "star-half-full" => "/(star-half-full)/",
    "star-half-o" => "/(star-half)/",
    "star-o" => "/(star)/",
    "steam-square" => "/(steam-square)/",
    "step-backward" => "/(step-backward)/",
    "step-forward" => "/(step-forward)/",
    "stethoscope" => "/(stethoscope)/",
    "sticky-note" => "/(sticky-note)/",
    "stop-circle" => "/(stop-circle)/",
    "street-view" => "/(street-view)/",
    "strikethrough" => "/(strikethrough)/",
    "stumbleupon" => "/(stumbleupon)/",
    "stumbleupon-circle" => "/(stumbleupon-circle)/",
    "subscript" => "/(subscript)/",
    "subway" => "/(subway)/",
    "suitcase" => "/(suitcase)/",
    "superpowers" => "/(superpowers)/",
    "superscript" => "/(superscript)/",
    "support" => "/(support)/",
    "tablet" => "/(tablet)/",
    "tachometer" => "/(tachometer)/",
    "telegram" => "/(telegram)/",
    "television" => "/(television)/",
    "tencent-weibo" => "/(tencent-weibo)/",
    "terminal" => "/(terminal)/",
    "text-height" => "/(text-height)/",
    "text-width" => "/(text-width)/",
    "th-large" => "/(th-large)/",
    "th-list" => "/(th-list)/",
    "themeisle" => "/(themeisle)/",
    "thermometer" => "/(thermometer)/",
    "thermometer-0" => "/(thermometer-0)/",
    "thermometer-1" => "/(thermometer-1)/",
    "thermometer-2" => "/(thermometer-2)/",
    "thermometer-3" => "/(thermometer-3)/",
    "thermometer-4" => "/(thermometer-4)/",
    "thermometer-empty" => "/(thermometer-empty)/",
    "thermometer-full" => "/(thermometer-full)/",
    "thermometer-half" => "/(thermometer-half)/",
    "thermometer-quarter" => "/(thermometer-quarter)/",
    "thermometer-three-quarters" => "/(thermometer-three-quarters)/",
    "thumb-tack" => "/(thumb-tack)/",
    "thumbs-down" => "/(thumbs-down)/",
    "thumbs-o-down" => "/(thumbs-down)/",
    "thumbs-o-up" => "/(thumbs-up)/",
    "thumbs-up" => "/(thumbs-up)/",
    "ticket" => "/(ticket)/",
    "times-circle" => "/(times-circle)/",
    "times-rectangle" => "/(times-rectangle)/",
    "toggle-down" => "/(toggle-down)/",
    "toggle-left" => "/(toggle-left)/",
    "toggle-off" => "/(toggle-off)/",
    "toggle-on" => "/(toggle-on)/",
    "toggle-right" => "/(toggle-right)/",
    "toggle-up" => "/(toggle-up)/",
    "trademark" => "/(trademark)/",
    "transgender" => "/(transgender)/",
    "transgender-alt" => "/(transgender-alt)/",
    "trash-o" => "/(trash)/",
    "trello" => "/(trello)/",
    "tripadvisor" => "/(tripadvisor)/",
    "trophy" => "/(trophy)/",
    "tumblr" => "/(tumblr)/",
    "tumblr-square" => "/(tumblr-square)/",
    "turkish-lira" => "/(turkish-lira)/",
    "twitch" => "/(twitch)/",
    "twitter" => "/(twitter)/",
    "twitter-square" => "/(twitter-square)/",
    "umbrella" => "/(umbrella)/",
    "underline" => "/(underline)/",
    "universal-access" => "/(universal-access)/",
    "university" => "/(university)/",
    "unlink" => "/(unlink)/",
    "unlock" => "/(unlock)/",
    "unlock-alt" => "/(unlock-alt)/",
    "unsorted" => "/(unsorted)/",
    "upload" => "/(upload)/",
    "user-circle" => "/(user-circle)/",
    "user-md" => "/(user-md)/",
    "user-plus" => "/(user-plus)/",
    "user-secret" => "/(user-secret)/",
    "user-times" => "/(user-times)/",
    "vcard-o" => "/(vcard)/",
    "venus-double" => "/(venus-double)/",
    "venus-mars" => "/(venus-mars)/",
    "viacoin" => "/(viacoin)/",
    "viadeo" => "/(viadeo)/",
    "viadeo-square" => "/(viadeo-square)/",
    "video-camera" => "/(video-camera)/",
    "vimeo-square" => "/(vimeo-square)/",
    "volume-control-phone" => "/(volume-control-phone)/",
    "volume-down" => "/(volume-down)/",
    "volume-off" => "/(volume-off)/",
    "volume-up" => "/(volume-up)/",
    "warning" => "/(warning)/",
    "wechat" => "/(wechat)/",
    "weixin" => "/(weixin)/",
    "whatsapp" => "/(whatsapp)/",
    "wheelchair" => "/(wheelchair)/",
    "wheelchair-alt" => "/(wheelchair-alt)/",
    "wikipedia-w" => "/(wikipedia-w)/",
    "window-close" => "/(window-close)/",
    "window-maximize" => "/(window-maximize)/",
    "window-minimize" => "/(window-minimize)/",
    "window-restore" => "/(window-restore)/",
    "windows" => "/(windows)/",
    "wordpress" => "/(wordpress)/",
    "wpbeginner" => "/(wpbeginner)/",
    "wpexplorer" => "/(wpexplorer)/",
    "wpforms" => "/(wpforms)/",
    "wrench" => "/(wrench)/",
    "xing-square" => "/(xing-square)/",
    "y-combinator" => "/(y-combinator)/",
    "y-combinator-square" => "/(y-combinator-square)/",
    "yc-square" => "/(yc-square)/",
    "youtube" => "/(youtube)/",
    "youtube-play" => "/(youtube-play)/",
    "youtube-square" => "/(youtube-square)/",
    "male" => "/(joel)/",
    "female" => "/(caitlin)/",
    "heart" => "/(us)/",
    "birthday-cake" => "/(birthdays)/",
  }
end
