import fs from 'node:fs'

const supportedLevels = ['trace', 'debug', 'info', 'warn', 'error', 'fatal'] as const

const levelMap = Object.fromEntries(
	supportedLevels.map((level, index) => [level, (index + 1) * 10])
) as Record<Level, number>
levelMap.silent = Number.MAX_SAFE_INTEGER
levelMap.all = 0

export type Level = 'silent' | (typeof supportedLevels)[number] | 'all'

type LogFunction = (objOrMsg: Record<string, unknown> | string, message?: string) => void

export interface Logger {
	name: string
	level: Level
	trace: LogFunction
	debug: LogFunction
	info: LogFunction
	warn: LogFunction
	error: LogFunction
	fatal: LogFunction
}

class ConsoleLogger implements Logger {
	constructor(
		public readonly name: string,
		public level: Level
	) {
		const log = (level: Level, objOrMsg: Record<string, unknown> | string, message?: string) => {
			const obj = typeof objOrMsg === 'string' ? {} : objOrMsg
			obj.msg = typeof objOrMsg === 'string' ? objOrMsg : (message ?? '')
			obj.name = this.name
			obj.level = level
			obj.time = new Date()
			if (levelMap[level] >= levelMap[this.level]) {
				console.log(...format(obj))
			}
		}

		Object.assign(
			this,
			Object.fromEntries<LogFunction>(
				supportedLevels.map((level) => [
					level,
					(objOrMsg, message) => log(level, objOrMsg, message)
				])
			)
		)
	}

	trace() {}
	debug() {}
	info() {}
	warn() {}
	error() {}
	fatal() {}
}

function format({ level, name, time, msg, ...obj }: Record<string, unknown>) {
	const result = [`[${(time as Date).toISOString()}] ${level} - ${name}`, msg]
	if (Object.keys(obj).length) {
		result.push(obj)
	}
	return result
}

const loggers = new Map<string, Logger>()

/* A logger name and its level. */
type LevelEntry = [string, Level]

let levelSpecs: LevelEntry[]

/* Synchronously reads the level confguration file, to build the level specification.. */
function readLevels() {
	const levelFile = process.env.LOG_LEVEL_FILE ?? '.log-levels'
	try {
		return buildLevels(fs.readFileSync(levelFile, 'utf8'))
	} catch (err) {
		if (!Error.isError(err) || !('code' in err) || err.code !== 'ENOENT') {
			throw new Error(`failed to read level file ${levelFile}: ${(err as Error).message}`)
		}
	}
	return []
}

/* Builds the level specification out of the configuration file content. */
function buildLevels(configuration: string): LevelEntry[] {
	return configuration
		? configuration
				.split('\n')
				.filter((n) => !n.startsWith('#') && n.includes('='))
				.map((term) => {
					const [spec = '', level = ''] = term
						.trim()
						.split('=')
						.map((n) => n.trim())
					if (!supportedLevels.includes(level as (typeof supportedLevels)[number])) {
						throw new Error(`unsupported log level ${level} for ${spec}`)
					}
					return [spec.replace(/\*/g, ''), level as Level]
				})
		: []
}

/**
 * Finds a logger level in the level specifications from its name.
 * The first specification entry which is a substring of the logger name will match.
 *
 * given specs of:  ['services/*', 'info']
 *                  ['services/tracks', 'error']
 *                  ['*', 'debug']
 * when computing level ot 'services/tracks'
 * then I'll get 'info'
 */
function computeLevel(name: string, levelSpecs: LevelEntry[]) {
	for (const [spec, level] of levelSpecs) {
		if (name.includes(spec)) {
			return level
		}
	}
	return null
}

function computeDefaultLevel(): Level {
	return process.env.NODE_ENV === 'test'
		? 'silent'
		: process.env.NODE_ENV === 'production'
			? 'info'
			: 'debug'
}

/**
 * Builds (or returns a built) a logger instance for a given name.
 * Built loggers are stored in memory so they could be quickly retrieved.
 * If not specified, the level will be computed from configuration file (LOG_LEVEL_PATH env variable)
 * with a default level set to 'info' ('debug' in dev mode, 'silent' in tests).
 * @param name Logger name
 * @param lvl Logger level
 */
export function getLogger(name = 'core', lvl: Level | undefined = undefined) {
	let logger = loggers.get(name)
	if (!logger) {
		if (!levelSpecs) {
			levelSpecs = readLevels()
		}
		const level = lvl || computeLevel(name, levelSpecs) || computeDefaultLevel()
		logger = new ConsoleLogger(name, level)
		loggers.set(name, logger)
	}
	return logger
}

/**
 * Updates level of all built loggers from the configuration file (.level)
 * Can be triggered by sending SIGUSR2 signal to the application.
 */
export function refreshLogLevels() {
	levelSpecs = readLevels()
	for (const [name, logger] of loggers) {
		const level = computeLevel(name, levelSpecs)
		if (level) {
			logger.level = level
		}
	}
}

process.on('SIGUSR2', refreshLogLevels)
