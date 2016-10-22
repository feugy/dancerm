module.exports =

  # buttons
  btn:
    addAddress: 'Editer'
    addDancer: 'Ajouter un danseur'
    addNewDancer: 'Nouveau'
    addExistingDancer: 'Existant'
    addInvoiceItem: 'Ajouter une ligne'
    addPayment: 'Nouveau paiement'
    addTeacher: 'Ajouter un professeur'
    callList: "Liste d'appel"
    cancel: 'Annuler'
    close: 'Fermer'
    detailed: 'Liste détaillée'
    editInvoice: 'Editer une facture pour {{owner}}'
    export: 'Exporter la liste'
    exportEmails: 'Copier les emails'
    ignore: 'Ignorer'
    invoice: 'Factures'
    import: 'Importer des données'
    lessons: 'Cours particuliers'
    markAsSent: 'Archiver'
    newDancer: 'Inscription'
    nextWeek: 'Semaine suivante'
    no: 'Non'
    ok: 'Ok'
    planning: 'Planning'
    previousWeek: 'Semaine précédente'
    printAddresses: 'Publipostage'
    printSettlement: 'Réglement intérieur (tampon {{owner}})'
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
    dumpFailed: "La sauvegarde externe des données à échouée: <%= message %>"
    exportFailed: "L'export de la liste de danseurs à échoué: <%= message %>"
    importFailed: "L'imporation du fichier de danseurs à échouée: {{message}}"
    search: 'La recherche à échouée: <%= message %>'
    missingAddress: 'ADRESSE MANQUANTE'

  # date/time formats
  formats:
    # angular format https://docs.angularjs.org/api/ng/filter/date
    birthSelection: 'dd/MM/yyyy'
    receiptSelection: 'dd/MM/yyyy'
    invoiceSelection: 'd MMMM yyyy'
    # moment format
    birth: 'DD/MM/YYYY'
    callList: 'DD/MM'
    invoice: 'D MMMM YYYY'
    lesson: 'ddd D MMM HH:mm'
    receipt: 'DD/MM/YYYY'

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
    classTooltip: '<p><%= kind %> (<%= level %>)</p><p><%= start %>~<%= end %></p>'
    currency: ' €'
    customer: 'Client'
    danceClasses: 'Cours'
    danceClassesFor: 'Cours pour'
    dancer: 'Danceur(se)'
    day: 'Jour'
    details: 'Détails'
    designation: 'Désignation'
    discount: 'Remise'
    due: 'Rgt.'
    dumpPath: 'Fichier de sauvegarde'
    dutyFreeTotal: 'Total HT'
    duration: 'Durée'
    durationUnit: ' minutes'
    email: 'E-mail'
    existingValue: 'Valeur actuelle'
    fieldSeparator: ' :'
    firstname: 'Prénom'
    Fri: 'Vendredi'
    genericDanceClass: 'Abonnement danse'
    horizontalMargin: 'Marge horizontale (mm)'
    hours: 'Horaire'
    invoiceDate: 'Emise le'
    importedValue: 'Valeur importée'
    invoiceItemLesson: 'Cours particulier'
    invoiceTotal: 'Total'
    invoiceTotalWithVat: 'Total TTC'
    knownBy: 'Connu par'
    lastname: 'Nom'
    lessonDetails: 'Détails'
    lessonInvoiced: 'Facturé'
    lessonKind: 'Danse'
    Mon: 'Lundi'
    noValue: 'pas de valeur'
    noVatSetting: 'Mention si non applicable'
    noVatMention: 'Non Soumis à T.V.A. Article C.G.I. 261, 4-4°b'
    noResults: 'Aucun résultat'
    other: '(autre)'
    payment: 'Réglement'
    paymentKind: 'Mode de réglement'
    payer: 'Par'
    payerPrefix: 'Prefix de recherche par payeur'
    period: 'Périodicité'
    phone: 'Téléphone'
    price: 'Prix'
    quantity: 'Qté.'
    rate: 'Tarif'
    receipt: 'Encaissement'
    ref: 'Réf.'
    registered: 'Intitulé du cours'
    registration: 'Inscription'
    Sat: 'Samedi'
    school: 'Ecole'
    ###schools: [
      owner: 'Diana'
      name: 'École de Danse P.M. Ribas'
      phone: 'Tél. 04 78 85 32 23'
      street: '34, rue du Docteur Rollet'
      zipcode: 69100
      city: 'Villeurbanne'
      siret: 'Siret 443 342 431 00014'
      vat: 'N° TVA FR68 443 342 431'
    ,
      owner: 'Anthony'
      name: 'École de Danse P.M. Ribas'
      phone: 'Tél. 04 78 85 32 23'
      street: '10, rue des Bons Amis'
      zipcode: 69100
      city: 'Villeurbanne'
      siret: 'Siret 499 909 935 00011'
      vat: 'Non Soumis à T.V.A. Article C.G.I. 261, 4-4°b'
      # Membre d'une Association Agréée par l'Administration fiscale. Le Règlement des honoraires par chèques libellés à mon nom est accepté
    ]###
    sent: 'Arch.'
    siret: 'Siret'
    street: 'Voie'
    Sun: 'Dimanche'
    sum: 'Total'
    taxTotal: 'Total TVA'
    theme: 'Thème'
    Thu: 'Jeudi'
    title: 'Titre'
    Tue: 'Mardi'
    teacher: 'Professeur'
    teacherColumn: 'Prof.'
    totalPrice: 'Montant'
    totalPriceWithVat: 'Montant HT'
    type: 'Type'
    stampWidth: 'Largeur (mm)'
    stampHeight: 'Hauteur (mm)'
    suggestedRef: 'Prochaine référence valide: {{ref}}'
    unitaryPrice: 'Prix unitaire'
    unitaryPriceWithVat: 'Prix unitaire HT'
    unknown: 'Inconnu'
    version: 'v{{version}}'
    value: 'Valeur'
    vatNumber: 'N° TVA'
    vatRate: 'Taux TVA'
    vatSettingsValue: 'Valeur'
    verticalMargin: 'Marge verticale (mm)'
    Wed: 'Mercredi'
    withVat: 'Appliquer la TVA'
    zipcode: 'Code postal'

  # long messages with html
  msg:
    about: "DanceRM est un logiciel de gestion de clientèle minimaliste développé pour l'école de danse Ribas à Villeurbanne."
    cancelEdition: "Vous allez perdre les modifications de {{names}}. Voulez-vous vraiment continuer ?"
    cancelLessonEdition: "Vous allez perdre les modifications du cours de {{firstname}} {{lastname}} du {{date}}. Voulez-vous vraiment continuer ?"
    configureTeachers: "Pour pouvoir éditer des factures, DanceRM à besoin de connaitre les coordonnéess, le Siret et éventuellement le numéro de TVA des proffesseurs"
    confirmGoBack: "Toutes les modifications non enregistrées vont être perdues. Voulez-vous vraiment continuer ?"
    confirmMarkAsSent: "Une fois archivée, la facture ne pourra plus être editée. Voulez-vous vraiment continuer ?"
    dancerListLength: ' danseur(s) séléctionné(s)'
    dumpData: "DanceRM réalise à chaque utilisation une sauvegarde externe de ses données. Merci de choisir l'emplacement de cette sauvegarde sur votre disque dur."
    dumping: 'Sauvegarde externe en cours, veuillez patienter...'
    editRegistration: "Modifier les cours du danseur pour l'année : "
    emptyDancerList: 'Aucun danseur pour ces critères'
    emptyInvoiceList: 'Aucune facture pour ces critères'
    emptyLessonList: 'Aucun cour particulier pour ces critères'
    exportEmails: "La liste des email suivante à été copiée dans le presse papier : <%= emails %>"
    exporting: 'Export en cours, veuillez patienter...'
    invoiceAlreadyExist: 'Une facture est déjà en cours d\'edition pour ce(tte) danceur(euse), et les cours particuliers ne peuvent lui être ajoutés. Voulez vous editer la facture en cours ?'
    invoiceListLength: ' facture(s) séléctionnée(s)'
    importing: 'Importation en cours, veuillez patienter...'
    importSuccess: """<p>{{byClass.Dancer || 'aucun'}} danseur(s), {{byClass.Card || 'aucune'}} fiche(s), {{byClass.Address || 'aucune'}} addresse(s), {{byClass.Invoice || 'aucune'}} facture(s), {{byClass.DanceClass || 'aucun'}} cour(s) et {{byClass.Lesson || 'aucun'}} cour(s) particulier(s) ont été importé(s) avec succès.</p>
  <p>Erreurs et corrections:</p>
  <p>{{errors.join('<br/>') || 'aucune'}}</p>
  """
    lessonListLength: ' cour(s) séléctionné(s)'
    pickHour: 'Veuillez sélectionner un heure'
    registrationSeason: "Choissiez l'année et le(s) cours : "
    removeAddress: "Vous allez supprimer l'address de {{dancer.firstname}} {{dancer.lastname}}. Il sa nouvelle addresse sera {{address.street}} {{address.zipcode}} {{address.city}}. Voulez-vous vraiment continuer ?"
    removeDancer: "Vous allez supprimer {{firstname}} {{lastname}}. La suppression ne sera définitive que lorsque vous enregistrez la fiche. Voulez vous vraiment continuer ?"
    removeLastDancer: "Vous allez supprimer définitivement la fiche de {{dancer.firstname}} {{dancer.lastname}}. Voulez vous vraiment continuer ?"
    removeLesson: "Vous allez supprimer le cours particulier de {{firstname}} {{lastname}} du {{date}}. Voulez-vous vraiment continuer ?"
    removeRegistration: "Vous allez supprimer les inscriptions et paiements de l'année {{season}}. Voulez-vous vraiment continuer ?"
    removePayment: "Vous allez supprimer le paiement par {{type}} de {{value}} € du {{receipt}}. Voulez-vous vraiment continuer ?"
    removeTeacher: "Vous allez supprimer définitivement le professeur {{owner}}, ainsi que ses cours particuliers et factures. Cette opération est irréversible. Voulez-vous vraiment continuer ?"
    requiredFields: "Les champs surlignés n'ont pas été remplis. Voulez vous tout de même enregistrer la fiche ?"
    requiredInvoiceFields: "Les champs surlignés n'ont pas été remplis. Voulez vous tout de même enregistrer la facture ?"
    requiredLessonFields: "Les champs surlignés n'ont pas été remplis. Voulez vous tout de même enrigstrer le cours ?"
    resolveConflict: "Pour résource le conflit, sélectionnez les valeurs à conserver avant d'enregistrer. Vous pouvez aussi ignorer le conflit et passer au suivant, ou annuler pour stopper la résolution."
    selectInvoice: 'Merci de selectionner une facture depuis la recherche, ou une fiche danseur'
    searchDancer: "En sélectionnant un danseur, vous fusionnerez sa fiche d'inscription avec celle de {{firstname}} {{lastname}}."
    searchDancerWarn: "Attention, cette opération est irréversible, et les modifications en cours seront enregistrées."

  placeholder:
    searchCards: 'danceurs par nom/prénom'
    searchLessons: 'cours par année/mois/danceur'
    searchInvoices: 'factures par année/mois/client'
    selectSeason: 'saison...'
    selectTeacher: 'professeur...'

  # print texts
  print:
    invoiceDate: 'Villeurbanne, le '
    invoiceDueDate: 'A régler au plus tard le '
    invoiceDelay: """En cas de retard de paiement, il sera appliqué des pénalités de {{delayFee}} % par mois de retard.
En outre, une indemnité forfaitaire pour frais de recouvrement de 40 € sera due.
Pas de condition d'escompte en cas de règlement anticipé."""
    invoiceVarious: "Acceptant le réglement des sommes dues par chèques libellés à son nom et en sa qualité de membre d'un centre de gestion agréé."
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
    weekDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    legend: 'Légende :'

  priceList:
    '2016/2017': [
      {category: 'Adultes, 1 an'}
      {name: 'Forfait 1h adulte', price: 283, quantity: 1, label: '1h'}
      {name: 'Forfait 1h adulte', price: 507, quantity: 2, label: '1h (couple)'}
      {name: 'Forfait 1h étudiant', price: 260, quantity: 1, label: '1h (étudiant)'}
      {name: 'Forfait 1h30 adulte', price: 382, quantity: 1, label: '1h30'}
      {name: 'Forfait 1h30 étudiant', price: 353, quantity: 1, label: '1h30 (étudiant)'}
      {name: 'Forfait 1h + 1h adulte', price: 481, quantity: 1, label: '1h + 1h'}
      {name: 'Forfait 1h + 1h adulte', price: 862, quantity: 2, label: '1h + 1h (couple)'}
      {name: 'Forfait 1h + 1h30 adulte', price: 565, quantity: 1, label: '1h + 1h30'}
      {name: 'Forfait 1h30 + 1h30 adulte', price: 649, quantity: 1, label: '1h30 + 1h30'}
      {name: 'Forfait Zumba 2 cours', price: 360, quantity: 1, '2 cours Zumba'}
      {category: 'Adultes, 1 trimestre'}
      {name: 'Forfait 1h adulte - trimestre', price: 105, quantity: 1, label: '1h'}
      {name: 'Forfait 1h adulte - trimestre', price: 194, quantity: 2, label: '1h (couple)'}
      {name: 'Forfait 1h étudiant - trimestre', price: 97, quantity: 1, label: '1h (étudiant)'}
      {name: 'Forfait 1h30 adulte - trimestre', price: 143, quantity: 1, label: '1h30'}
      {name: 'Forfait 1h30 étudiant - trimestre', price: 132, quantity: 1, label: '1h30 (étudiant)'}
      {name: 'Forfait 1h + 1h adulte - trimestre', price: 178, quantity: 1, label: '1h + 1h'}
      {name: 'Forfait 1h + 1h adulte - trimestre', price: 330, quantity: 2, label: '1h + 1h (couple)'}
      {name: 'Forfait 1h + 1h30 adulte - trimestre', price: 211, quantity: 1, label: '1h + 1h30'}
      {name: 'Forfait 1h30 + 1h30 adulte - trimestre', price: 243, quantity: 1, label: '1h30 + 1h30'}
      {category: 'Cours'}
      {name: 'Cours 1h adulte', price: 12, quantity: 1, label: '1h adulte'}
      {name: 'Cours 1h30 adulte', price: 14, quantity: 1, label: '1h30 adulte'}
      {name: 'Cours particulier 1 ou 2 personnes', price: 43, quantity: 1, label: 'CP 1/2 personnes'}
      {name: 'Cours particulier 3 personnes', price: 52, quantity: 1, label: 'CP 3 personnes'}
      {name: 'Cours particulier 4 personnes', price: 66, quantity: 1, label: 'CP 4 personnes'}
      {category: 'Enfant/ados, 1 an'}
      {name: 'Forfait 45 minutes enfants/ado', price: 191, quantity: 1, label: '45 minutes'}
      {name: 'Forfait 1h enfants/ado', price: 254, quantity: 1, label: '1h'}
      {name: 'Forfait 1h30 enfants/ado', price: 343, quantity: 1, label: '1h30'}
      {name: 'Forfait 1h + 45 minutes enfants/ado', price: 379, quantity: 1, label: '1h + 45 minutes'}
      {name: 'Forfait 1h + 1h enfants/ado', price: 432, quantity: 1, label: '1h + 1h'}
      {name: 'Forfait 1h30 + 45 minutes enfants/ado', price: 454, quantity: 1, label: '1h30 + 45 minutes'}
      {name: 'Forfait 1h + 1h30 enfants/ado', price: 508, quantity: 1, label: '1h + 1h30'}
      {category: 'Enfant/ados, 1 trimestre'}
      {name: 'Forfait 45 minutes enfants/ados - trimestre', price: 72, quantity: 1, label: '45 minutes'}
      {name: 'Forfait 1h enfants/ados - trimestre', price: 95, quantity: 1, label: '1h'}
      {name: 'Forfait 1h30 enfants/ados - trimestre', price: 128, quantity: 1, label: '1h30'}
      {name: 'Forfait 1h + 45 minutes enfants/ados - trimestre', price: 142, quantity: 1, label: '1h + 45 minutes'}
      {name: 'Forfait 1h + 1h enfants/ados - trimestre', price: 161, quantity: 1, label: '1h + 1h'}
      {name: 'Forfait 1h30 + 45 minutes enfants/ados - trimestre', price: 170, quantity: 1, label: '1h30 + 45 minutes'}
      {name: 'Forfait 1h + 1h30 enfants/ados - trimestre', price: 190, quantity: 1, label: '1h + 1h30'}
      {category: 'Compétiteurs'}
      {name: 'Entainements dirigés latine (D, E, F)', price: 320, quantity: 1, label: 'latine D,E,F'}
      {name: 'Entainements dirigés & libres latine (A, B, C)', price: 360, quantity: 1, label: 'latine A,B,C'}
      {name: 'Entainements dirigés standard (D, E, F)', price: 260, quantity: 1, label: 'standard D,E,F'}
      {name: 'Entainements dirigés & libres standard (A, B, C)', price: 360, quantity: 1, label: 'standard A,B,C'}
      {name: 'Entainements dirigés & libres 10 dances (A, B, C)', price: 420, quantity: 1, label: '10 danses'}
      {name: 'Entrainement seul', price: 12, quantity: 1, label: 'cours seul'}
    ]

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

  # Tooltips
  tip:
    searchCards: 'Chercher des danceurs'
    searchLessons: 'Chercher des cours particuliers'
    searchInvoices: 'Chercher des factures'

  # titles
  ttl:
    about: 'A propos'
    address: 'Adresse'
    application: 'DanceRM'
    card: 'Fiche danseurs'
    confirm: 'Confirmation'
    contact: 'Contact'
    currentWeek: '{{from}} au {{to}} {{monthAndYear}}'
    danceClassesDistribution: 'Distibution des cours'
    dancerList: 'Liste des danseurs'
    dancer: 'Danseur'
    database: 'Base de données'
    duePayment: 'Impayés'
    dumping: 'Sauvegarde des données'
    editLesson: 'Cours particulier'
    editRegistration: 'Modification de l\'inscription'
    export: 'Exportation'
    generalInfo: 'Information'
    import: 'Importation'
    invoice: 'Facture N°{{ref}}'
    invoiceDisplay: '{{owner}} - Facture archivée N°{{ref}}'
    invoiceEdition: '{{owner}} - Edition de la facture N°{{ref}}'
    interface: 'Interface'
    knownBy: 'Connu par'
    knownByRepartition: 'Ils ont connus par...'
    missingCertificates: 'Certificats manquants'
    newRegistration: 'Nouvelle inscription'
    print: 'DanceRM : impression pour {{names}}'
    resolveConflict: "Résolution de conflit {{rank+1}}/{{conflicts.length}}"
    removeError: 'Erreur de suppression'
    saveError: 'Erreur de sauvegarde'
    settlementPrint: "<p>Réglement</p><p>{{registration.season}}</p>"
    search: 'Recherche de danseurs'
    searchDancer: 'Fusionner deux fiches'
    stats: '{{total}} danseurs'
    teacherSettings: 'Professeurs inscrits'
    vatSettings: 'Paramètres de TVA'