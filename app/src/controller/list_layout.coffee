module.exports = class ListLayoutController
              
  # Controller dependencies
  @$inject: ['cardList', '$state']

  @declaration:
    controller: ListLayoutController
    controllerAs: 'ctrl'
    templateUrl: 'list_layout.html'

  # Link to card list service
  cardList: null

  # Link to Angular's state provider
  state: null

  # Displayed columns
  columns: [
    {name: 'firstname', title: 'lbl.firstname'}
    {name: 'lastname', title: 'lbl.lastname'}
    {name: 'certified', title: 'lbl.certified', attr: (dancer, done) -> 
      dancer.getLastRegistration (err, registration) -> done err, registration?.certified(dancer) or false
    }
    {name: 'due', title: 'lbl.due', attr: (dancer, done) -> 
      dancer.getLastRegistration (err, registration) -> done err, registration?.due() or 0
    }
  ]

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param cardList [CardListService] service responsible for card list
  # @param state [Object] Angular's state provider
  constructor: (@cardList, @state) -> 

  # Displays a given dancer on the main part
  #
  # @param dancer [Dancer] choosen dancer
  displayCard: (dancer) =>
    console.log "ask to display #{dancer.id}"
    @state.go 'list.card', id: dancer.cardId

  # @return true if the current list concerned a dance class
  canPrintCallList: =>
    @cardList.criteria.string is null and @cardList.criteria.danceClasses.length is 1

  # Print call list from the current day
  # 
  # @param danceClass [DanceClass] danceClass concerned
  printCallList: =>
    try
      preview = window.open 'call_list_print.html'
      preview.danceClass = @cardList.criteria.danceClasses[0]
      preview.list = @cardList.list
    catch err
      console.error err
    # TODO a bug obviously
    global.console = window.console