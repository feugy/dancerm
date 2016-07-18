module.exports =

  # buttons
  btn:
    addAddress: 'Editer'
    addDancer: 'Ajouter un danseur'
    addNewDancer: 'Nouveau'
    addExistingDancer: 'Existant'
    addPayment: 'Nouveau paiement'
    callList: "Liste d'appel"
    cancel: 'Annuler'
    close: 'Fermer'
    detailed: 'Liste détaillée'
    export: 'Exporter la liste'
    exportEmails: 'Copier les emails'
    ignore: 'Ignorer'
    import: 'Importer des données'
    newDancer: 'Inscription'
    no: 'Non'
    ok: 'Ok'
    planning: 'Planning'
    printAddresses: 'Publipostage'
    printSettlement: 'Réglement intérieur'
    printWithoutVat: 'Sans TVA, sans cours'
    printWithVat: 'Avec TVA, sans cours'
    printWithoutVatWithClasses: 'Sans TVA'
    printWithVatWithClasses: 'Avec TVA'
    print: 'Imprimer'
    register: 'Inscription'
    remove: 'Supprimer'
    removeAddress: 'Supprimer'
    save: 'Enregistrer'
    stats: 'Statistiques'
    settings: 'Paramètres'
    yes: 'Oui'

  # civility mapping
  civilityTitles: ['M.', 'Mme', 'Mlle']

  # charts colors, retrieved from theme
  colors: []

  # errors
  err:
    dumpFailed: "La sauvegarde externe des données à échouée: %s"
    exportFailed: "L'export de la liste de danseurs à échoué: %s"
    importFailed: "L'imporation du fichier de danseurs à échouée: {{message}}"
    search: 'La recherche à échouée: %s'
    missingAddress: 'ADRESSE MANQUANTE'

  # date/time formats
  formats:
    birthSelection: 'dd/MM/yyyy' # angular format https://docs.angularjs.org/api/ng/filter/date
    receiptSelection: 'dd/MM/yyyy' # angular format https://docs.angularjs.org/api/ng/filter/date
    birth: 'DD/MM/YYYY' # moment format
    receipt: 'DD/MM/YYYY' # moment format
    callList: 'DD/MM'

  # short labels
  lbl:
    address: 'Adresse'
    age: 'Age'
    allDanceClasses: 'tous les cours'
    allSeasons: 'toutes les saisons'
    allTeachers: 'tous les professeurs'
    author: 'by {{author}}'
    bank: 'Banque'
    birth: 'Né(e) le'
    card: 'Fiche danseurs'
    cellphone: 'Portable'
    certificates: 'Nb. certificats'
    certified: 'Cert.'
    certifiedLong: 'Certificat médical'
    charged: 'Réglement de'
    choose: '---'
    city: 'Ville'
    classTooltip: '%s (%s) %s~%s'
    currency: '€'
    danceClasses: 'Cours'
    danceClassesFor: 'Cours pour'
    day: 'Jour'
    details: 'Détails'
    due: 'Rgt.'
    dumpPath: 'Fichier de sauvegarde'
    email: 'E-mail'
    existingValue: 'Valeur actuelle'
    fieldSeparator: ' :'
    firstname: 'Prénom'
    Fri: 'Vendredi'
    genericDanceClass: 'Abonnement danse'
    horizontalMargin: 'Marge horizontale (mm)'
    hours: 'Horaire'
    importedValue: 'Valeur importée'
    knownBy: 'Connu par'
    lastname: 'Nom'
    Mon: 'Lundi'
    noValue: 'pas de valeur'
    noResults: 'Aucun résultat'
    other: '(autre)'
    payment: 'Réglement'
    paymentKind: 'Mode de réglement'
    payer: 'Par'
    period: 'Périodicité'
    phone: 'Téléphone'
    rate: 'Tarif'
    receipt: 'Encaissement'
    registered: 'Intitulé du cours'
    registration: 'Inscription'
    Sat: 'Samedi'
    street: 'Voie'
    Sun: 'Dimanche'
    sum: 'Total'
    theme: 'Thème'
    Thu: 'Jeudi'
    title: 'Titre'
    Tue: 'Mardi'
    type: 'Type'
    stampWidth: 'Largeur (mm)'
    stampHeight: 'Hauteur (mm)'
    unknown: 'Inconnu'
    version: 'v{{version}}'
    value: 'Valeur'
    vat: 'dont T.V.A.'
    vatTeachers: 'Enseignants soumis à la TVA'
    vatValue: 'TVA'
    verticalMargin: 'Marge verticale (mm)'
    Wed: 'Mercredi'
    zipcode: 'Code postal'

  # long messages with html
  msg:
    about: "DanceRM est un logiciel de gestion de clientèle minimaliste développé pour l'école de danse Ribas à Villeurbanne."
    cancelEdition: "Vous allez perdre les modification apportée à {{names}}. Voulez-vous vraiment continuer ?"
    confirmGoBack: "Toutes les modifications non enregistrée vont être perdues. Voulez-vous vraiment continuer ?"
    dancerListLength: ' danseur(s) séléctionné(s)'
    dumpData: "DanceRM réalise à chaque utilisation une sauvegarde externe de ses données. Merci de choisir l'emplacement de cette sauvegarde sur votre disque dur."
    dumping: 'Sauvegarde externe en cours, veuillez patienter...'
    editRegistration: "Modifier les cours du danseur pour l'année : "
    emptyDancerList: 'Aucun danseur pour ces critères'
    exportEmails: "La liste des email suivante à été copiée dans le presse papier : %s"
    exporting: 'Export en cours, veuillez patienter...'
    importing: 'Importation en cours, veuillez patienter...'
    importSuccess: "{{Dancer || 'aucun'}} danseur(s), {{Card || 'aucune'}} fiche(s), {{Address || 'aucune'}} addresse(s) et {{DanceClass || 'aucun'}} cour(s) ont été importé(s) avec succès."
    registrationSeason: "Choissiez l'année et le(s) cours : "
    removeAddress: "Vous allez supprimer l'address de {{dancer.firstname}} {{dancer.lastname}}. Il sa nouvelle addresse sera {{address.street}} {{address.zipcode}} {{address.city}}. Voulez-vous vraiment continuer ?"
    removeDancer: "Vous allez supprimer {{firstname}} {{lastname}}. La suppression ne sera définitive que lorsque vous enregistrez la fiche. Voulez vous vraiment continuer ?"
    removeLastDancer: "Vous allez supprimer définitivement la fiche de {{dancer.firstname}} {{dancer.lastname}}. Voulez vous vraiment continuer ?"
    removeRegistration: "Vous allez supprimer les inscriptions et paiements de l'année {{season}}. Voulez-vous vraiment continuer ?"
    removePayment: "Vous allez supprimer le paiement par {{type}} de {{value}}€ du {{receipt}}. Voulez-vous vraiment continuer ?"
    requiredFields: "Les champs surlignés n'ont pas été remplis. Voulez vous tout de même enregistrer la ficher ?"
    resolveConflict: "Pour résource le conflit, sélectionnez les valeurs à conserver avant d'enregistrer. Vous pouvez aussi ignorer le conflit et passer au suivant, ou annuler pour stopper la résolution."
    searchDancer: "En sélectionnant un danseur, vous fusionnerez sa fiche d'inscription avec celle de {{firstname}} {{lastname}}."
    searchDancerWarn: "Attention, cette opération est irréversible, et les modifications en cours seront enregistrées."

  placeholder:
    search: 'chercher par nom/prénom'
    selectSeason: 'saison...'
    selectTeacher: 'professeur...'

  # print texts
  print:
    # to detect dancers on multiple teachers groups
    teacherGroups:
      anthony: 1
      diana: 2
      delphine: 2
      nassim: 2
    school: """
<p>Ecole de danse Ribas</p>
<p>34 rue du docteur Rollet</p>
<p>69100 Villeurbanne</p>
"""
    settlement: """
<h2>Accès aux activités</h2>
<p>L'accès aux activités est strictement réservé aux membres de l'école à jour de leurs cotisations.</p>
<p>La direction se réserve le droit de refuser l'entrée ou le renvoi de toute personne dont le comportement ou la mauvaise tenue pourraient être contraire à la sécurité, à la réputation et aux intérêts de l'école, et ceci sans dédommagement concernant son abonnement.
Les abonnements sont strictement personnels.</p>
<p>Les tarifs prennent en compte la fermeture pour congés et jours fériés.
Les cours collectifs sont interrompus pendant les vancances scolaires.</p>
<h2>Responsabilités</h2>
<p>De son coté, le membre déclare souscrire une police d'assurance engageant sa responsabilité civile, le couvrant de ses activités dans l'enceinte de l'école.
La responsabilité de l'école ne pourra être recherchée en cas d'accident résultant de la non-observation des consignes de sécurité ou de l'utilisation inappropriée du matériel.</p>
<p>Pour chaque cours, excepté les danses de couple, l'adhérent devra fournir un certificat médical de non contre indication à la discipline.
S'il n'est pas fourni dans les 15 jours suivant l'inscription, l'école et le professeur dégagent toute responsabilité en cas d'accident.</p>
<p>Un trimestre payé et non suivi ne pourra être reporté ou remboursé. Une année payée et non suivie ne pourra être reportée ou remboursée.</p>
<p>Les cours particuliers, non-annulés 48h à l'avance seront dus.</p>
<p>Afin de ne pas perturber les cours qui se déroulent dans les salles, celles-ci sont inerdites à toute personne non concernée par le cours.</p>
<p>Pour la tranquilité du voisinage, il est demandé de ne pas faire de bruit à la sortie de l'école.</p>
<p>Les enfants en peuvent pas rester sans la surveillance de leurs parents tant que le cours n'est pas commencé.
De même, les parents qui viennent chercher les enfants sont priés de bien vouloir monter à l'école.</p>
<p>Vous acceptez de bien vouloir apparaitre sur les photos et les vidéos des différentes manifestations de l'école de dans Ribas.</p>
<h2>L'inscription et la fréquentation de l'école de danse Ribas entrainent obligatoirement l'acceptation du présent réglement.</h2>
"""
    settlementTitle: "Reglement intérieur / Conditions générale d'adhésion"
    sign: "<p>Signature de l'élève ou du responsable légal</p><p>Précédé de la mention \"lu et approuvé\"</p>"
    stamp: "Signature et cachet de l'école"
    # lower case name of teacher that need VAT
    vatTeachers: ['delphine', 'nassim']
    where: "Fait à"
    when: "le"

  # payment types
  paymentTypes:
    cash: 'Espèces'
    check: 'Chèque'
    traveler: 'ANCV'

  # payment periods
  periods:
    'class': "au cours"
    quarter: "au trimestre"
    year: "à l'année"

  # planning directive configuration values
  planning:
    # must be same days used in DanceClass's start and end attributes
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
    legend: 'Légende :'

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

  # Theme's list
  themes:
    dark: 'Dark'
    none: "'The' original"

  # titles
  ttl:
    about: 'A propos'
    address: 'Adresse'
    application: 'DanceRM'
    card: 'Fiche danseurs'
    confirm: 'Confirmation'
    contact: 'Contact'
    danceClassesDistribution: 'Distibution des cours'
    dancerList: 'Liste des danseurs'
    dancer: 'Danseur'
    database: 'Base de données'
    duePayment: 'Impayés'
    dumping: 'Sauvegarde des données'
    editRegistration: 'Modification de l\'inscription'
    export: 'Exportation'
    generalInfo: 'Information'
    import: 'Importation'
    interface: 'Interface'
    knownBy: 'Connu par'
    knownByRepartition: 'Ils ont connus par...'
    missingCertificates: 'Certificats manquants'
    newRegistration: 'Nouvelle inscription'
    print: 'DanceRM : impression pour {{names}}'
    settlementPrint: "<p>Réglement</p><p>{{registration.season}}</p>"
    resolveConflict: "Résolution de conflit {{rank+1}}/{{conflicts.length}}"
    search: 'Recherche de danseurs'
    searchDancer: 'Fusionner deux fiches'
    stats: '{{total}} danseurs'
    vatSettings: 'Paramètres de TVA'

  # VAT rate
  vat: 0.196