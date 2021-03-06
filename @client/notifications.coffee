
require './watch_star'


# Toggle homepage filter to watched proposals
document.addEventListener "keypress", (e) -> 
  key = (e and e.keyCode) or e.keyCode

  if key==23 # cntrl-W
    filter = fetch 'homepage_filter'
    filter.watched = !filter.watched
    save filter



window.Notifications = ReactiveComponent
  displayName: 'Notifications'

  render : -> 
    data = @data()

    settings = {}
    current_user = fetch('/current_user')

    subdomain = fetch('/subdomain')

    prefs = current_user.subscriptions

    loc = fetch('location')

    if loc.query_params?.unsubscribe
      if current_user.subscriptions['send_emails']
        current_user.subscriptions['send_emails'] = null 
        save current_user
        @local.unsubscribed = true 
        save @local 
      delete loc.query_params.unsubscribe
      save loc

    DIV 
      style:
        width: HOMEPAGE_WIDTH()
        margin: '0px auto'

      if @local.unsubscribed && !current_user.subscriptions['send_emails']
        DIV 
          style: 
            border: "1px solid #{logo_red}" 
            color: logo_red
            padding: '4px 8px'

          TRANSLATE
            id: "email_notifications.unsubscribed_ack"
            subdomain_name: subdomain.name
            "You are unsubscribed from summary emails from {subdomain_name}.consider.it"

      DIV
        style: 
          fontSize: 24
          marginBottom: 10
          position: 'relative'

        H1 
          style: 
            fontSize: 28
            padding: '20px 0'
            fontWeight: 400

          TRANSLATE "email_notifications.heading", 'Email notification settings'
          
        INPUT 
          type: 'checkbox'
          defaultChecked: !!prefs['send_emails']
          id: 'enable_email'
          name: 'enable_email'
          style: 
            verticalAlign: 'top'
            display: 'inline-block'
            marginTop: 12
            fontSize: 24
            position: 'absolute'
            left: -40

          onChange: (e) => 

            if prefs['send_emails'] 
              current_user.subscriptions['send_emails'] = null
            else
              current_user.subscriptions['send_emails'] = settings['default_subscription']
            save current_user
            e.stopPropagation()

        DIV 
          style: 
            display: 'inline-block'

          LABEL
            htmlFor: 'enable_email'              

            SPAN 
              style: 
                color: focus_color()
                fontWeight: 600

              TRANSLATE "email_notifications.send_digests", 'Send me email summaries of activity'

            DIV
              style: 
                fontSize: 14
                color: '#888'

              TRANSLATE 
                id: "email_notifications.digests_purpose", 
                project_name: subdomain.name
                "The emails summarize relevant new activity for you regarding {project_name}"


      if prefs['send_emails']
        [@drawEmailSettings()

        @drawWatched()]



  drawEmailSettings : () -> 
    current_user = fetch('/current_user')
    settings = current_user.subscriptions

    DIV 
      style: 
        #backgroundColor: '#f2f2f2'
        padding: '10px 10px 10px 30px'

      LABEL
        htmlFor: 'send_digests_at_most' 
        style: 
          marginRight: 10
          display: 'inline-block'

        TRANSLATE "email_notifications.digest_timing", "Send email summaries at most"


      SELECT 
        id: 'send_digests_at_most'
        style: 
          width: 120
          fontSize: 18
        value: settings['send_emails']
        onChange: (e) => 
          current_user.subscriptions['send_emails'] = e.target.value
          save current_user

        for u in ['hour', 'day', 'week', 'month']
          OPTION
            value: "1_#{u}"
            if u == 'day'
              translator "email_notifications.frequency.daily", 'daily'
            else
              translator "email_notifications.frequency.#{u}ly", "#{u}ly"

      DIV 
        style: 
          marginTop: 15

        DIV
          style: 
            marginBottom: 10

          TRANSLATE 'email_notifications.notable_events', "Emails are only sent if a notable event occurred. Which events are notable to you?"

        UL
          style: 
            listStyle: 'none'

          # prefs contains keys of objects being watched, and event trigger
          # preferences for different events
          for event in _.keys(settings).sort()
            config = settings[event]

            continue if not config.ui_label

            LI 
              style: 
                display: 'block'
                padding: '5px 0'

              SPAN 
                style: 
                  display: 'inline-block'
                  verticalAlign: 'top'
                  position: 'relative'

                INPUT 
                  id: "#{event}_input"
                  name: "#{event}_input"
                  type: 'checkbox'
                  checked: if config.email_trigger then true
                  style: 
                    fontSize: 24
                    position: 'absolute'
                    left: -30
                    top: 2
                  onChange: do (config) => => 
                    config.email_trigger = !config.email_trigger
                    save current_user

              LABEL
                htmlFor: "#{event}_input"
                style: 
                  display: 'inline-block'
                  verticalAlign: 'top'

                TRANSLATE "email_notifications.event.#{event}", config.ui_label

  drawWatched: ->
    current_user = fetch('/current_user')
    unsubscribed = {}

    for k,v of current_user.subscriptions
      # we only match proposals for now 
      if v == 'watched' && k.match(/\/proposal\//)
        unsubscribed[k] = v

    if _.keys(unsubscribed).length > 0

      DIV 
        style: 
          padding: '20px 0'

        H2
          style: 
            fontSize: 24
            position: 'relative'
            paddingBottom: 10
            fontWeight: 400

          TRANSLATE "email_notifications.watched_proposals", 'The proposals you are watching for new activity'


        DIV
          style: 
            width: 550
            display: 'inline-block'

          UL
            style: 
              position: 'relative'
              paddingLeft: 30

            for k,v of unsubscribed
              do (k) => 
                obj = fetch(k)

                LI 
                  style: 
                    listStyle: 'none'
                    padding: '5px 0'
                    position: 'relative'

                  WatchStar
                    proposal: obj
                    #icon: 'fa-bell-slash'
                    watch_color: "#777"
                    label: (watching) -> translator "email_notifications.unfollow_proposal", "Unfollow this proposal"
                      
                    style: 
                      position: 'absolute'
                      left: -35
                      top: 3
                  A 
                    href: "/#{obj.slug}"
                    style: 
                      textDecoration: 'underline'

                    obj.name 

                  # A 
                  #   style: 
                  #     cursor: 'pointer'
                  #     display: 'inline-block'
                  #     marginLeft: 10
                  #     fontSize: 14
                  #   onClick: => 
                  #     delete current_user.subscriptions[k]
                  #     save current_user

                  #   'stop watching'   
