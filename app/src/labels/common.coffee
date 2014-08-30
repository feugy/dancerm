module.exports = 
  
  # titles  
  ttl:
    address: 'Adresse'
    application: 'DanceRM'
    card: 'Fiche danceurs'
    confirm: 'Confirmation'
    contact: 'Contact'
    dancerList: 'Liste des danseurs'
    dancer: 'Danceur'
    dump: 'Sauvegarde externe'
    editRegistration: 'Modification de l\'inscription'
    export: 'Exportation'
    generalInfo: 'Information'
    import: 'Importation'
    knownBy: 'Connu par'
    newRegistration: 'Nouvelle inscription'
    print: 'DanceRM : impression pour {{names}}'
    registrationPrint: "<p>Fiche d'inscription</p><p>{{registration.season}}</p>"
    search: 'Recherche de danseurs'
    
  # long messages with html
  msg:
    cancelEdition: "Vous allez perdre les modification apportée à %s. Voulez-vous vraiment continuer ?"
    confirmGoBack: "Toutes les modifications non enregistrée vont être perdues. Voulez-vous vraiment continuer ?"
    dancerListLength: ' danseur(s) séléctionné(s)'
    dumpData: "DanceRM réalise à chaque utilisation une sauvegarde externe de ses données. Merci de choisir l'emplacement de cette sauvegarde sur votre disque dur."
    dumping: 'Sauvegarde externe en cours, veuillez patienter...'
    editRegistration: "Modifier les cours du danceur"
    emptyDancerList: 'Aucun danseur pour ces critères'
    exportEmails: "La liste des email suivante à été copiée dans le presse papier : %s"
    exporting: 'Export en cours, veuillez patienter...'
    importing: 'Importation en cours, veuillez patienter...'
    importSuccess: "{{Dancer || 'aucun'}} danseur(s), {{Card || 'aucune'}} fiche(s), {{Address || 'aucune'}} addresse(s) et {{DanceClass || 'aucun'}} cour(s) ont été importé(s) avec succès."
    registrationSeason: "Choissiez l'année et le(s) cours : "
    removeRegistration: "Vous allez supprimer l'inscription pour l'année %s. Voulez-vous vraiment continuer ?"
    removePayment: "Vous allez supprimer le paiement par %s de %.2f € du %s. Voulez-vous vraiment continuer ?"
    requiredFields: "Les champs surlignés n'ont pas été remplis. Voulez vous tout de même enregistrer la ficher ?"

  # buttons
  btn: 
    addAddress: 'Editer'
    addDancer: 'Nouveau danceur'
    addPayment: 'Nouveau paiement'
    backToList: 'Retour au planning'
    cancel: 'Annuler'
    close: 'Fermer'
    export: 'Exporter la liste'
    exportEmails: 'Copier les emails'
    import: 'Importer des danseurs'
    newDancer: 'Inscrire un danseur'
    no: 'Non'
    ok: 'Ok'
    printWithoutVat: 'Sans TVA'
    printWithVat: 'Avec TVA'
    print: 'Imprimer'
    callList: "Liste d'appel"
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
    certifiedLong: 'Certificat médical'
    charged: 'Réglement de'
    choose: '---'
    city: 'Ville'
    classTooltip: '%s (%s) %s~%s'
    currency: '€'
    danceClasses: 'Cours pour'
    day: 'Jour'
    details: 'Détails'
    due: 'Rgt.'
    email: 'E-mail'
    fieldSeparator: ' :'
    firstname: 'Prénom'
    Fri: 'Vendredi'
    lastname: 'Nom'
    hours: 'Horaire'
    Mon: 'Lundi'
    other: '(autre)'
    paymentKind: 'Mode de réglement'
    payer: 'Par'
    phone: 'Téléphone'
    rate: 'Tarif'
    receipt: 'Encaissement'
    registered: 'Intitulé du cours'
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
    vat: 'dont T.V.A.'
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
    birthSelection: 'dd/MM/yyyy' # angular format https://docs.angularjs.org/api/ng/filter/date
    receiptSelection: 'dd/MM/yyyy' # angular format https://docs.angularjs.org/api/ng/filter/date
    birth: 'DD/MM/YYYY' # moment format
    receipt: 'DD/MM/YYYY' # moment format
    callList: 'DD/MM'

  # print texts
  print:
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
<p>Pour chaque cours, excepté les danses de couple, l'adhérent devra founrir un certificat médical de non contre indication à la discipline.
S'il n'est pas fourni dans les 15 jours suivants l'inscription, l'école et le professeur dégagent toute responsabilité en cas d'accident.</p>
<p>Un trimestre payé et non suivi ne pourra être reporté ou remboursé. Une année payée et non suivie ne pourra être reportée ou remboursée.</p>
<p>Les cours particuliers, non-annulés 48h à l'avance seront dus.</p>
<p>Afin de ne pas perturber les cours qui se déroulent dans les salles, celle-ci sont inerdites à toute personne non concernée par le cours.</p>
<p>Pour la tranquilité du voisinage, il est demandé de ne pas faire de bruit à la sortie de l'école.</p>
<p>Les enfants en peuvent pas rester sans la surveillance de leurs parents tant que le cours n'est pas commencé.
De même, les parents qui viennent chercher les enfants sont priés de bien vouloir monter à l'école.</p>
<p>Vous acceptez de bien vouloir apparaitre sur les photos et les vidéos des différentes manifestations de l'école de dans Ribas.</p>
<h2>L'inscription et la fréquentation de l'école de danse Ribas entrainent obligatoirement l'acceptation du présent réglement.</h2>
"""
    settlementTitle: "Reglement intérieur / Conditions générale d'adhesion"
    sign: "<p>Signature de l'élève ou du responsable légal</p><p>Précédé de la mention \"lu et approuvé\"</p>"
    stamp: "Signature et cachet de l'école"
    where: "Fait à"
    when: "le"

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