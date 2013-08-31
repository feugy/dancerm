module.exports = 
  
  # titles  
  ttl:
    application: 'DanceRM'
    generalInfo: 'Information'
    address: 'Adresse'
    contact: 'Contact'
    newRegistration: 'Nouvelle inscription'
    editRegistration: "Modification de l'inscription"
    confirm: 'Confirmation de la suppression'
    dancerList: 'Liste des danceurs'
    import: 'Importation'
    dump: 'Sauvegarde externe'
    search: 'Recherche de danseurs'

  # long messages with html
  msg:
    registrationSeason: "Choissiez l'année et le(s) cours : "
    removeRegistration: "Vous allez supprimer l'inscription pour l'année %s. Voulez-vous vraiment continuer ?"
    removePayment: "Vous allez supprimer le paiement par %s de %.2f € du %s. Voulez-vous vraiment continuer ?"
    cancelEdition: "Vous allez perdre les modification apportée à %s %s. Voulez-vous vraiment continuer ?"
    confirmGoBack: "Toutes les modifications non enregistrée vont être perdues. Voulez-vous vraiment continuer ?"
    importSuccess: "%d/%d danseur(s) importé(s) (les autres existaient déjà)"
    dumpData: "DanceRM réalise à chaque utilisation une sauvegarde externe de ses données. Merci de choisir l'emplacement de cette sauvegarde sur votre disque dur."

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
    ok: 'Ok'
    addPayment: 'Nouveau paiement'
    backToList: 'Retour à la liste'
    import: 'Importer des danseurs'

  # short labels
  lbl:
    fieldSeparator: ' :'
    firstname: 'Prénom'
    lastname: 'Nom'
    street: 'Voie'
    zipcode: 'Code postal'
    city: 'Ville'
    phone: 'Téléphone'
    cellphone: 'Portable'
    email: 'E-mail'
    birth: 'Date de naissance'
    certified: 'Certificat médical'
    danceClasses: 'Cours'
    charged: 'Réglement de'
    currency: '€'
    receipt: 'Encaissement'
    bank: 'Banque'
    details: 'Détails'
    knownBy: 'Connu par'
    value: 'Valeur'
    sum: 'Total'
    other: 'autre'
    Mon: 'Lundi'
    Tue: 'Mardi'
    Wed: 'Mercredi'
    Thu: 'Jeudi'
    Fri: 'Vendredi'
    Sat: 'Samedi'
    Sun: 'Dimanche'

  # errors
  err:
    importFailed: "L'imporation du fichier de danseurs à échouée: %s"
    dumpFailed: "La sauvegarde externe des données à échouée: %s"
    search: 'La recherche à échouée: %s'

  # formats
  formats:
    birth: "DD/MM/YYYY"
    receipt: "DD/MM/YYYY"

  # civility mapping
  civilityTitles: ['M.', 'Mme', 'Mlle']

  # payment types
  paymentTypes: 
    check: 'Chèque'
    cash: 'Espèces'
    traveler: 'Ch. vacance'

  # payment periods
  periods:
    year: "à l'année"
    quarter: "au trimestre"
    'class': "au cours"

  # different ways to learn the school existence
  knownByMeanings:
    leaflets: 'tract'
    website: 'notre site web'
    pagejaunesFr: 'pagejaunes.fr'
    searchEngine: 'moteur de recherche'
    directory: 'annuaire'
    associationsBiennal: 'biennale des asso.'
    mouth: 'bouche à oreille'

  # planning directive configuration values
  planning:
    # must be same days used in DanceClass's start and end attributes
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
    legend: 'Légende :'