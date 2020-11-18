
window.NewProposal = ReactiveComponent
  displayName: 'NewProposal'

  render : -> 
    list_name = @props.list_name or 'Proposals'
    list_key = "list/#{list_name}"

    list_state = fetch(@props.local)
    loc = fetch 'location'

    return SPAN null if list_name == 'Blocksize Survey'

    current_user = fetch '/current_user'

    if list_state.adding_new_proposal != list_name && \
       loc.query_params.new_proposal == encodeURIComponent(list_name)
      list_state.adding_new_proposal = list_name
      save list_state

    adding = list_state.adding_new_proposal == list_name 
    list_slug = slugify(list_name)

    permitted = permit('create proposal')
    needs_to_login = permitted == Permission.NOT_LOGGED_IN
    permitted = permitted > 0

    @local.category ||= list_name

    return SPAN null if !permitted && !needs_to_login

    proposal_fields = customization('new_proposal_fields', list_name)()

    label_style = 
      fontWeight: 400
      fontSize: 14
      display: 'block'

    if customization('show_proposer_icon', list_key) && adding 
      editor = current_user.user
      # Person's icon
      bullet = Avatar
        key: editor
        user: editor
        img_size: 'large'
        style:
          #position: 'absolute'
          #left: -18 - 50
          height: 50
          width: 50
          marginRight: 8
          borderRadius: 0
          backgroundColor: '#ddd'

    # else if !adding

    #   bullet =  SVG 
    #               viewBox: "0 0 5 5"
    #               width: 20
    #               style: 
    #                 marginRight: 7
    #                 verticalAlign: 'top'
    #                 paddingTop: 6

    #               PATH 
    #                 fill: '#000000'
    #                 d: "M2 1 h1 v1 h1 v1 h-1 v1 h-1 v-1 h-1 v-1 h1 z"
    else
      bullet =  SVG 
                  width: 8
                  viewBox: '0 0 200 200' 
                  style: 
                    marginRight: 7 + (if !adding then 6 else 0)
                    marginLeft: 6
                    verticalAlign: 'top'
                    paddingTop: 13
                  CIRCLE cx: 100, cy: 100, r: 80, fill: '#000000'


    if !adding 
      BUTTON  
        name: "add_new_#{list_name}"
        className: 'add_new_proposal'
        style: _.defaults (@props.label_style or {}),
          cursor: 'pointer'
          backgroundColor: '#e7e7e7'
          border: 'none'
          fontSize: 20
          fontWeight: 600
          padding: '6px 36px 6px 16px'
          textDecoration: 'underline'
          borderRadius: 8
          marginLeft: -44
        
        onClick: (e) => 
          loc.query_params.new_proposal = encodeURIComponent list_name
          save loc

          if permitted
            list_state.adding_new_proposal = list_name; save(list_state)
            setTimeout =>
              $("##{list_slug}-name").focus()
            , 0
          else 
            e.stopPropagation()
            reset_key 'auth', {form: 'login', goal: 'add a new proposal', ask_questions: true}
        
        A name: "new_#{list_name}"
        bullet 

        if permitted
          translator "engage.add_new_proposal_to_list", 'add new'
        else 
          translator "engage.login_to_add_new_proposal", 'Log in to share an idea'

    else 

      w = column_sizes().first
      
      DIV 
        style:
          position: 'relative'
          padding: '6px 8px'
          marginLeft: if customization('show_proposer_icon', list_key) then -76 else -36

        A name: "new_#{list_name}"

        if customization('new_proposal_tips', list_key)
          @drawTips customization('new_proposal_tips', list_key)

        bullet

        DIV 
          style: 
            position: 'relative'
            display: 'inline-block'

          LABEL 
            style: _.extend {}, label_style, 
              position: 'absolute'
              left: 8
              top: -18
            htmlFor: "#{list_slug}-name"

            proposal_fields.name



          CharacterCountTextInput 
            id: "#{list_slug}-name"
            maxLength: 240
            name:'name'
            pattern: '^.{3,}'
            'aria-label': translator("engage.edit_proposal.summary.placeholder", 'Clear and concise summary')
            placeholder: translator("engage.edit_proposal.summary.placeholder", 'Clear and concise summary')
            required: 'required'

            count_style: 
              position: 'absolute'
              right: 0
              top: -18 
              fontSize: 14  

            style: 
              fontSize: 20
              width: w
              border: "1px solid #ccc"
              outline: 'none'
              padding: '6px 8px'
              fontWeight: 600
              #textDecoration: 'underline'
              #borderBottom: "1px solid #444"  
              color: '#000'
              minHeight: 75        
              resize: 'vertical'    

        DIV 
          style: 
            position: 'relative'
            marginLeft: if customization('show_proposer_icon', list_key) then 58 else 21


          # details 
          DIV null,

            LABEL 
              style: _.extend {}, label_style,
                marginLeft: 8

              htmlFor: "#{list_slug}-details"

              proposal_fields.description

            WysiwygEditor
              id: "#{list_slug}-details"
              key:"description-new-proposal-#{list_slug}"
              #placeholder: translator("engage.edit_proposal.description.placeholder", 'Add details here')  
              'aria-label': translator("engage.edit_proposal.description.placeholder", 'Add details here')  
              container_style: 
                padding: '6px 8px'
                border: '1px solid #ccc'

              style: 
                fontSize: 16
                width: w - 8 * 2
                marginBottom: 8
                minHeight: 120

          for additional_field in proposal_fields.additional_fields 
            # details 
            DIV null,

              LABEL 
                style: _.extend {}, label_style,
                  marginLeft: 8

                htmlFor: "#{list_slug}-#{additional_field}"

                proposal_fields[additional_field]

              WysiwygEditor
                id: "#{list_slug}-#{additional_field}"
                key:"#{additional_field}-new-proposal-#{list_slug}"
                'aria-label': proposal_fields[additional_field]
                container_style: 
                  padding: '6px 8px'
                  border: '1px solid #ccc'

                style: 
                  fontSize: 16
                  width: w - 8 * 2
                  marginBottom: 8
                  minHeight: 120


          if @local.errors?.length > 0
            
            DIV
              role: 'alert'
              style:
                fontSize: 18
                color: 'darkred'
                backgroundColor: '#ffD8D8'
                padding: 10
                marginTop: 10
              for error in @local.errors
                DIV null, 
                  I
                    className: 'fa fa-exclamation-circle'
                    style: {paddingRight: 9}

                  SPAN null, error

          DIV 
            style: 
              marginTop: 14

            BUTTON 
              className: 'submit_new_proposal'
              style: 
                backgroundColor: focus_color()
                color: 'white'
                cursor: 'pointer'
                # borderRadius: 16
                padding: '4px 16px'
                display: 'inline-block'
                marginRight: 12
                border: 'none'
                boxShadow: '0 1px 1px rgba(0,0,0,.9)'
                fontWeight: 600
                # fontSize: 'inherit'

              onClick: => 
                name = $(@getDOMNode()).find("##{list_slug}-name").val()

                fields = 
                  description: fetch("description-new-proposal-#{list_slug}").html

                for field in proposal_fields.additional_fields
                  fields[field] = fetch("#{field}-new-proposal-#{list_slug}").html

                description = proposal_fields.create_description(fields)
                active = true 
                hide_on_homepage = false
                category = list_name

                proposal =
                  key : '/new/proposal'
                  name : name
                  description : description
                  cluster : category
                  active: active
                  hide_on_homepage: hide_on_homepage

                InitializeProposalRoles(proposal)
                
                proposal.errors = []
                @local.errors = []
                save @local

                save proposal, => 
                  if proposal.errors?.length == 0
                    list_state.adding_new_proposal = null 
                    save list_state
                    delete loc.query_params.new_proposal
                    save loc                      
                  else
                    @local.errors = proposal.errors
                    save @local

              translator 'engage.done_button', 'Done'

            BUTTON 
              style: 
                color: '#888'
                cursor: 'pointer'
                backgroundColor: 'transparent'
                border: 'none'
                padding: 0
                fontSize: 'inherit'                  
              onClick: => 
                list_state.adding_new_proposal = null; 
                save(list_state)
                delete loc.query_params.new_proposal
                save loc

              translator 'engage.cancel_button', 'cancel'

  componentDidMount : ->    
    @ensureIsInViewPort()

  componentDidUpdate : -> 
    @ensureIsInViewPort()

  ensureIsInViewPort : -> 
    loc = fetch 'location'
    local = fetch @props.local

    is_selected = loc.query_params.new_proposal == encodeURIComponent((@props.list_name or 'Proposals'))

    if is_selected
      if browser.is_mobile
        $(@getDOMNode()).moveToTop {scroll: false}
      else
        $(@getDOMNode()).ensureInView {scroll: false}




  drawTips : (tips) -> 
    # guidelines/tips for good points
    mobile = browser.is_mobile
    return SPAN null if mobile

    guidelines_w = if mobile then 'auto' else 330
    guidelines_h = 300

    DIV 
      style:
        position: if mobile then 'relative' else 'absolute'
        right: -guidelines_w - 20
        width: guidelines_w
        color: focus_color()
        zIndex: 1
        marginBottom: if mobile then 20
        backgroundColor: if mobile then 'rgba(255,255,255,.85)'
        fontSize: 14


      if !mobile
        SVG
          width: guidelines_w + 28
          height: guidelines_h
          viewBox: "-4 0 #{guidelines_w+20 + 9} #{guidelines_h}"
          style: css.crossbrowserify
            position: 'absolute'
            transform: 'scaleX(-1)'
            left: -20

          PATH
            stroke: focus_color() #'#ccc'
            strokeWidth: 1
            fill: "#FFF"

            d: """
                M#{guidelines_w},33
                L#{guidelines_w},0
                L1,0
                L1,#{guidelines_h} 
                L#{guidelines_w},#{guidelines_h} 
                L#{guidelines_w},58
                L#{guidelines_w + 20},48
                L#{guidelines_w},33 
                Z
               """
      DIV 
        style: 
          padding: if !mobile then '14px 18px'
          position: 'relative'
          marginLeft: 5

        SPAN 
          style: 
            fontWeight: 600
            fontSize: 24
          "Tips"

        UL 
          style: 
            listStylePosition: 'outside'
            marginLeft: 16
            marginTop: 5

          do ->
            tips = customization('new_proposal_tips')

            for tip in tips
              LI 
                style: 
                  paddingBottom: 3
                  fontSize: if PORTRAIT_MOBILE() then 24 else if LANDSCAPE_MOBILE() then 14
                tip  

