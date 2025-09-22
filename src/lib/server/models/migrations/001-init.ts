import type { DatabaseSync } from 'node:sqlite'

export async function up(db: DatabaseSync) {
	db.exec(`
CREATE TABLE dancer (
	id TEXT PRIMARY KEY,
	_v INTEGER DEFAULT 1,
	created DATETIME DEFAULT CURRENT_TIMESTAMP,
	title TEXT,
	firstname TEXT,
	lastname TEXT,
	cellphone TEXT,
	email TEXT,
	birth DATETIME
)`)

	db.exec(`
INSERT INTO dancer (created, title, firstname, lastname, cellphone, email, birth, id, _v) VALUES
	('2016-10-05T11:45:58.682Z', 'Mme', 'Leona', 'Lika', '0675718640', 'adelinalika@hotmail.com', '2009-08-16T22:00:00.000Z', '0006b11481cf', 2),
	('2023-09-04T14:12:23.796Z', 'Mlle', 'MAXINE', 'NAZARET', '0625300536', 'aureliacalistri@gmail.com', '2018-05-06T22:00:00.000Z', '0026c924cbd7', 4),
	('2016-10-11T16:13:07.529Z', 'M.', 'Laurence', 'Chevalerias', '0770428726', 'laurence.chevalerias@hotmail.fr', '1989-03-19T23:00:00.000Z', '002a17ba0fce', 3),
	('2019-09-13T14:22:47.199Z', 'Mlle', 'LORY', 'CORBION', '0647404945', 'corbion.lory@gmail.com', '1998-12-25T23:00:00.000Z', '00453a0ae07e', 7),
	('2013-09-02T10:23:29.405Z', 'Mlle', 'Elyä', 'Ouattara',null, 'yainaithembela@hotmail.fr', '2003-12-31T23:00:00.000Z', '004c9f991e4c', 5),
	('2013-09-02T10:23:42.152Z', 'Mlle', 'Alison', 'Blaszczyk', '625152824',null, '1992-12-31T23:00:00.000Z', '00764ebfbf2b', 5),
	('2022-09-07T18:51:35.423Z', 'Mme', 'LAURIANE', 'AGNELOT', '0625906470', 'laurianea48@gmail.com', '1999-07-02T22:00:00.000Z', '0098ddd350e0', 9),
	('2018-09-04T13:35:04.452Z', 'Mlle', 'MAEVA', 'FARHAT', '0658145873', 'sonia.laugier@laposte.net', '2006-07-19T13:36:03.260Z', '00b200720f1d', 2)`)
}
