define [
  'underscore'
  'moment'
  '../model/dancer/dancer'
  '../model/planning/planning'
], (_, moment, Dancer, Planning) ->
   
  # Export utility class.
  # Allow exportation of dancers and planning into JSON plain files 
  class Export

    # Dump storage content into a plain JSON file, for further restore
    #
    # @param path [FileEntry] path to the dump data
    # @param callback [Function] dump end callback, invoked with arguments:
    # @option callback err [Error] an Error object, or null if no problem occurred
    dump: (fileEntry, callback) =>
      return callback new Error "no file selected" unless fileEntry?
      console.info "dump data in #{fileEntry.fullPath}..."
      start = moment()
      fileEntry.createWriter (writer) =>
        stored =
        	plannings: []
        	dancers: []

      	# termination callbacks
        writer.onerror = callback
        writer.onabort = callback
        writer.onwriteend = (event) =>
      		duration = moment().diff start, 'seconds'
     			console.info "data dumped in #{duration}s"
      		callback null

        # gets plannings
        Planning.findAll (err, plannings) =>
        	return callback new Error "Failed to dump plannings: #{err.toString()}" if err?
        	stored.plannings = plannings
        	# gets dancers
        	Dancer.findAll (err, dancers) =>
	        	return callback new Error "Failed to dump dancers: #{err.toString()}" if err?
	        	stored.dancers = dancers
        		# eventually, write into the file
      			writer.write new Blob [JSON.stringify(stored, null, 2)], type: 'text/plain'
