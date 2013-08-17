define root:
  
  # titles  
  ttl:
    application: 'DanceRM'
    generalInfo: 'Information'
    address: 'Adresse'
    contact: 'Contact'
    newRegistration: 'Nouvelle inscription'
    confirmRemove: 'Confirmation de la suppression'
    dancerList: 'Liste des danceurs'

  # long messages with html
  msg:
    registrationYear: "Choissiez l'année et le cours : "
    removeRegistration: "Vous allez supprimer l'inscription pour l'année %s. Voulez-vous vraiment continuer ?"
    removePayment: "Vous allez supprimer le paiement par %s de %.2f €. Voulez-vous vraiment continuer ?"

  # buttons
  btn: 
    newDancer: 'Nouveau danseur'
    register: 'Nouvelle Inscription'
    cancel: 'Annuler'
    save: 'Enregistrer'
    edit: 'Modifier'
    remove: 'Supprimer'
    yes: 'Oui'
    no: 'Non'
    addPayment: 'Nouveau paiement'

  # short labels
  lbl:
    fieldSeparator: ' :'
    firstname: 'Prénom'
    lastname: 'Nom'
    street: 'Voie'
    zipcode: 'Code postal'
    city: 'Ville'
    phone: 'Téléphone'
    email: 'E-mail'
    birth: 'Date de naissance'
    certified: 'Certificat médical'
    danceClasses: 'Cours'
    payments: 'A régler'
    currency: '€'
    details: 'Dét.'
    Mon: 'Lundi'
    Tue: 'Mardi'
    Wed: 'Mercredi'
    Thu: 'Jeudi'
    Fri: 'Vendredi'
    Sat: 'Samedi'
    Sun: 'Dimanche'

  # formats
  formats:
    datePicker: "dd/MM/yyyy"
    receipt: "DD/MM"

  # civility mapping
  civilityTitles: ['M.', 'Mme', 'Mlle']

  # payment types
  paymentTypes: 
    check: 'Chèque'
    cash: 'Espèces'
    card: 'Carte'
    transfer: 'Virement'

  # planning directive configuration values
  planning:
    # must be same days used in DanceClass's start and end attributes
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
    # earliest and latest displayed hours (included)
    earliest: 12
    latest: 21
    
  # default dancer value for creation
  defaultDancer:
    firstname: 'Anne'
    lastname: 'Dupond'
    birth: '1980-04-20'
    certified: true
    address:
      street: '1 rue de la République'
      zipcode: 69001
      city: 'Lyon'