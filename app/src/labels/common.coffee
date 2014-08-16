module.exports = 
  
  # titles  
  ttl:
    address: 'Adresse'
    application: 'DanceRM'
    card: 'Fiche danceurs'
    confirm: 'Confirmation de la suppression'
    contact: 'Contact'
    dancerList: 'Liste des danseurs'
    dancer: 'Danceur'
    dump: 'Sauvegarde externe'
    export: 'Exportation'
    generalInfo: 'Information'
    import: 'Importation'
    knownBy: 'Connu par'
    newRegistration: 'Nouvelle inscription'
    print: 'DanceRM : impression pour %s %s'
    registrationPrint: 'Inscription année %s'
    search: 'Recherche de danseurs'
    
  # long messages with html
  msg:
    cancelEdition: "Vous allez perdre les modification apportée à %s. Voulez-vous vraiment continuer ?"
    confirmGoBack: "Toutes les modifications non enregistrée vont être perdues. Voulez-vous vraiment continuer ?"
    dancerListLength: ' danseur(s) séléctionné(s)'
    dumpData: "DanceRM réalise à chaque utilisation une sauvegarde externe de ses données. Merci de choisir l'emplacement de cette sauvegarde sur votre disque dur."
    dumping: 'Sauvegarde externe en cours, veuillez patienter...'
    emptyDancerList: 'Aucun danseur pour ces critères'
    exportEmails: "La liste des email suivante à été copiée dans le presse papier : %s"
    exporting: 'Export en cours, veuillez patienter...'
    importing: 'Importation en cours, veuillez patienter...'
    importSuccess: "%d/%d danseur(s) importé(s) (les autres existaient déjà)"
    registrationSeason: "Choissiez l'année et le(s) cours : "
    removeRegistration: "Vous allez supprimer l'inscription pour l'année %s. Voulez-vous vraiment continuer ?"
    removePayment: "Vous allez supprimer le paiement par %s de %.2f € du %s. Voulez-vous vraiment continuer ?"

  # buttons
  btn: 
    addDancer: 'Nouveau danceur'
    addPayment: 'Nouveau paiement'
    backToList: 'Retour au planning'
    cancel: 'Annuler'
    close: 'Fermer'
    edit: 'Modifier'
    export: 'Exporter la liste'
    exportEmails: 'Copier les emails'
    import: 'Importer des danseurs'
    newDancer: 'Inscrire un danseur'
    no: 'Non'
    ok: 'Ok'
    print: 'Imprimer'
    register: 'Inscription'
    remove: 'Supprimer'
    save: 'Enregistrer'
    yes: 'Oui'

  # short labels
  lbl:
    address: 'Adresse'
    age: 'Age'
    allTeachers: 'tous les professeurs'
    bank: 'Banque'
    birth: 'Né(e) le'
    cellphone: 'Portable'
    certified: 'Cert.'
    certifiedLong: 'Certificat'
    charged: 'Réglement de'
    choose: '---'
    city: 'Ville'
    classTooltip: '%s (%s) %s~%s'
    currency: '€'
    danceClasses: 'Cours pour'
    details: 'Détails'
    due: 'Rgt.'
    email: 'E-mail'
    fieldSeparator: ' :'
    firstname: 'Prénom'
    Fri: 'Vendredi'
    lastname: 'Nom'
    Mon: 'Lundi'
    other: '(autre)'
    payer: 'Par'
    phone: 'Téléphone'
    receipt: 'Encaissement'
    registeredFemale: 'Inscrite au(x) cours'
    registeredMale: 'Inscrit au(x) cours'
    Sat: 'Samedi'
    searchPlaceholder: 'chercher par nom/prénom'
    street: 'Voie'
    Sun: 'Dimanche'
    sum: 'Total'
    Thu: 'Jeudi'
    title: 'Titre'
    Tue: 'Mardi'
    type: 'Type'
    value: 'Valeur'
    Wed: 'Mercredi'
    zipcode: 'Code postal'

  # errors
  err:
    dumpFailed: "La sauvegarde externe des données à échouée: %s"
    exportFailed: "L'export de la liste de danseurs à échoué: %s"
    importFailed: "L'imporation du fichier de danseurs à échouée: %s"
    search: 'La recherche à échouée: %s'

  # date/time formats
  formats:
    birthSelection: 'dd/MM/yyyy' # datepicker format http://angular-ui.github.io/bootstrap/#/datepicker
    receiptSelection: 'dd/MM/yyyy' # datepicker format http://angular-ui.github.io/bootstrap/#/datepicker
    birth: 'DD/MM/YYYY' # moment format
    receipt: 'DD/MM/YYYY' # moment format

  # print texts
  print:
    sign: "Signature"
    what: "ai pris connaissance et approuve le règlement intérieur de l'Ecole de Danse RIBAS."
    when: "Villeurbanne, le"
    whoFemale: "Je soussignée"
    whoMale: "Je soussigné"
    certificate: "Et m'engage a fournir un certificat valide pour la pratique de la danse."

  # civility mapping
  civilityTitles: ['M.', 'Mme', 'Mlle']

  # payment types
  paymentTypes: 
    cash: 'Espèces'
    check: 'Chèque'
    traveler: 'Ch. vacance'

  # payment periods
  periods:
    'class': "au cours"
    quarter: "au trimestre"
    year: "à l'année"

  # different ways to learn the school existence
  knownByMeanings:
    associationsBiennal: 'biennale asso.'
    directory: 'annuaire'
    elders: 'anciens'
    groupon: 'groupon'
    leaflets: 'tract'
    mouth: 'bouche à oreille'
    pagesjaunesFr: 'pagesjaunes.fr'
    searchEngine: 'moteur de recherche'
    website: 'site web'

  # planning directive configuration values
  planning:
    # must be same days used in DanceClass's start and end attributes
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
    legend: 'Légende :'