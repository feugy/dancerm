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
    ignore: 'Ne rien modifier'
    invoice: 'Factures'
    invoiceWithoutRegistration: 'Factures hors inscriptions'
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
    saveConflict: 'Sauver les valeurs cochées'
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
    certified: 'Certificat médical'
    charged: 'Réglement de'
    choose: '---'
    city: 'Ville'
    classTooltip: '<p><%= kind %> (<%= level %>)</p><p><%= start %>~<%= end %></p>'
    color: 'Couleur'
    currency: ' €'
    customer: 'Client'
    creditTotal: 'Net à votre crédit'
    creditTotalWithVat: 'Net à votre crédit TTC'
    danceClasses: 'Cours'
    danceClassesFor: 'Cours pour'
    dancer: 'Danceur(se)'
    day: 'Jour'
    details: 'Détails'
    designation: 'Désignation'
    discount: 'Remise'
    due: 'Réglement'
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
    hall: 'Salle'
    horizontalMargin: 'Marge horizontale (mm)'
    hours: 'Horaire'
    invoiceDate: 'Emise le'
    importedValue: 'Valeur importée'
    invoiceItemLesson: 'Cours particulier'
    invoiceTotal: 'Net à payer'
    invoiceTotalWithVat: 'Net à payer TTC'
    isCredit: 'Avoir'
    json: 'Fichier JSON'
    kind: 'Danse/Style'
    knownBy: 'Connu par'
    lastname: 'Nom'
    lessonDetails: 'Détails'
    lessonInvoiced: 'Facturé'
    lessonKind: 'Danse'
    level: 'Niveau'
    Mon: 'Lundi'
    noValue: 'pas de valeur'
    noVatSetting: 'Mention si non applicable'
    noVatMention: 'Non Soumis à T.V.A. Article C.G.I. 261, 4-4°b'
    noResults: 'Aucun résultat'
    other: '(autre)'
    payment: 'Réglement'
    paymentKind: 'Mode de réglement'
    payer: 'Par'
    payerPrefix: 'Prefixe de recherche par payeur'
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
    xlsx: 'Classeur Excel'
    zipcode: 'Code postal'

  # long messages with html
  msg:
    about: "DanceRM est un logiciel de gestion de clientèle minimaliste développé pour l'école de danse Ribas à Villeurbanne."
    cancelConflictResolution: """En annulant, les prochains conflits seront ignorés.
Si vous souhaitez reprendre la résolution de ces conflits plus tard, il suffit d'importer de nouveau le même fichier.
Voulez vous interrompre la résolution des conflits ?"""
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
    exportEmails: "<p>La liste des email suivante à été copiée dans le presse papier :</p><p><%= emails %></p>"
    exporting: 'Export en cours, veuillez patienter...'
    invoiceAlreadyExist: 'Une facture est déjà en cours d\'edition pour ce(tte) danceur(euse), et les cours particuliers ne peuvent pas lui être ajoutés. Voulez vous editer la facture en cours ?'
    invoiceListLength: ' facture(s) séléctionnée(s)'
    importing: 'Importation en cours, veuillez patienter...'
    importSuccess: """<p>{{byClass.Dancer || 'aucun'}} danseur(s), {{byClass.Card || 'aucune'}} fiche(s), {{byClass.Address || 'aucune'}} addresse(s), {{byClass.Invoice || 'aucune'}} facture(s), {{byClass.DanceClass || 'aucun'}} cour(s) et {{byClass.Lesson || 'aucun'}} cour(s) particulier(s) ont été importé(s) avec succès.</p>
  <p>Erreurs et corrections:</p>
  <p>{{errors.join('<br/>') || 'aucune'}}</p>
  """
    lessonListLength: ' cour(s) séléctionné(s)'
    pickHour: 'Cliquez sur le planning pour sélectionner une heure'
    readOnlyLesson: "Ce cours à déjà été facturé, il ne peut être modifié."
    registrationSeason: "Choissiez l'année et le(s) cours : "
    removeAddress: "Vous allez supprimer l'address de {{dancer.firstname}} {{dancer.lastname}}. Il sa nouvelle addresse sera {{address.street}} {{address.zipcode}} {{address.city}}. Voulez-vous vraiment continuer ?"
    removeDancer: "Vous allez supprimer {{firstname}} {{lastname}}. La suppression ne sera définitive que lorsque vous enregistrez la fiche. Voulez vous vraiment continuer ?"
    removeDanceClass: "Vous allez définitivement supprimer le cours {{kind}} {{level}} du {{start}}. Il y a {{dancers}} inscrit(s). Voulez vous vraiment continuer ?"
    removeLastDancer: "Vous allez supprimer définitivement la fiche de {{firstname}} {{lastname}}. Voulez vous vraiment continuer ?"
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
    updateInstalled: "<p>Une nouvelle mise à jour ({{version}}) est à été installée, et sera appliquée au prochain redémarrage.</p><p>Voulez vous redémarrer maintenant ?</p>"

  placeholder:
    searchCards: 'danceurs par nom/prénom'
    searchLessons: 'cours par année/mois/danceur'
    searchInvoices: 'factures par ref/année/mois/client'
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
    default: [{category: 'Aucun prix défini'}]

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
    newSeason: 'Ajouter la nouvelle saison'
    searchCards: 'Chercher des danceurs'
    searchLessons: 'Chercher des cours particuliers'
    searchInvoices: 'Chercher des factures'

  # titles
  ttl:
    about: 'A propos'
    address: 'Adresse'
    application: 'DanceRM'
    card: 'Fiche danseurs'
    chooseDumpLocation: 'Selection du fichier de sauvegarde'
    chooseExportLocation: 'Selection du fichier à exporter'
    chooseImportedFile: 'Selection du fichier à importer'
    confirm: 'Confirmation'
    contact: 'Contact'
    currentWeek: '{{from}} au {{to}} {{monthAndYear}}'
    credit: 'Avoir N°{{ref}}'
    danceClassesDistribution: 'Distibution des cours'
    dancerList: 'Liste des danseurs'
    dancer: 'Danseur'
    database: 'Base de données'
    duePayment: 'Impayés'
    dumping: 'Sauvegarde des données'
    editCourse: 'Cours'
    editLesson: 'Cours particulier'
    editRegistration: 'Modification de l\'inscription'
    export: 'Exportation'
    generalInfo: 'Information'
    import: 'Importation'
    invalidOperation: 'Opération invalide'
    invoice: 'Facture N°{{ref}}'
    invoiceDisplay: '{{owner}} - Facture archivée N°{{ref}}'
    invoiceEdition: '{{owner}} - Edition de la facture N°{{ref}}'
    interface: 'Interface'
    knownBy: 'Connu par'
    knownByRepartition: 'Ils ont connus par...'
    missingCertificates: 'Certificats manquants'
    newRegistration: 'Nouvelle inscription'
    planningSettings: 'Plannings'
    print: 'DanceRM : impression pour {{names}}'
    resolveConflict: "Résolution de conflit {{rank+1}}/{{conflicts.length}}"
    removeError: 'Erreur de suppression'
    saveError: 'Erreur de sauvegarde'
    settlementPrint: "<p>Réglement</p><p>{{registration.season}}</p>"
    search: 'Recherche de danseurs'
    searchDancer: 'Fusionner deux fiches'
    season: 'Saison'
    stats: '{{total}} danseurs'
    teacherSettings: 'Professeurs inscrits'
    updateInstalled: 'Mise à jour disponible'
    vatSettings: 'Paramètres de TVA'