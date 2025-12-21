import type { DatabaseSync } from 'node:sqlite'

export async function up(db: DatabaseSync) {
	db.exec(`
CREATE TABLE card (
	id TEXT PRIMARY KEY,
	_v INTEGER DEFAULT 1,
	knownBy BLOB NOT NULL,
	registrations BLOB NOT NULL
)`)
	db.exec(`
CREATE TABLE address (
	id TEXT PRIMARY KEY,
	_v INTEGER DEFAULT 1,
	street TEXT,
	zipcode INTEGER,
	city TEXT,
	phone TEXT
)`)
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
	birth DATETIME,
	cardId TEXT,
	addressId TEXT
)`)

	db.exec(`
INSERT INTO address (street, zipcode, city, phone, id, _v) VALUES
	('19 rue pierre J proudhon', 69100, 'Villeurbanne', null, '6f1f21897fe6', 3),
	('5 RUE PAUL LAFARGUE', 69100, 'VILLEURBANNE', '0625342635', '0e5c70835a2e', 1),
	('14 rue du Boulevard', 69100, 'Villeurbanne', null, '70f84cf40958', 3),
	('29 COURS LAFAYETTE', 69006, 'LYON', null, '095d17c43a77', 2),
	('A déménagé en 2014', 0, null, null, 'ca2f55e23d4a', 6),
	('134, crs tolstoï', 69100, 'Villeurbanne', null, '9267b765d193', 5),
	('36 RUE PAUL VERLAINE', 69100, 'VILLEURBANNE', null, 'f131d7a9302d', 2),
	('33 RUE CLEMENT MICHUT', 69100, 'VILLEURBANNE', null, 'b262a9c7d050', 2)`)

	db.exec(`
INSERT INTO card (knownBy, registrations, id, _v) VALUES
  (jsonb('[]'), jsonb('[{"created":null,"season":"2016/2017","certificates":{"0006b11481cf":true},"charged":254,"period":"year","details":null,"payments":[{"type":"check","value":85,"receipt":"2016-10-14T22:00:00.000Z","payer":"Meazi","bank":null,"details":null},{"type":"check","value":85,"receipt":"2016-11-15T12:48:27.469Z","payer":"Meazi","bank":null,"details":null},{"type":"check","value":84,"receipt":"2016-12-15T12:48:29.136Z","payer":"Meazi","bank":null,"details":null}],"invoiceIds":[]}]'), 'd292733a4246', 3),
  (jsonb('[]'), jsonb('[{"created":"2025-07-15T18:36:16.869Z","season":"2025/2026","certificates":{},"charged":370,"period":"year","details":null,"payments":[{"type":"cash","value":370,"receipt":"2025-07-15T18:36:30.365Z","payer":"NAZARET","bank":null,"details":null}],"invoiceIds":[]}]'), '7396a6525739', 8),
  (jsonb('[]'), jsonb('[{"created":null,"season":"2016/2017","certificates":{},"charged":507,"period":"year","details":null,"payments":[{"type":"check","value":194,"receipt":"2016-10-11T16:16:18.952Z","payer":"Chevalerias","bank":null,"details":"doivent changer pour l''année"},{"type":"check","value":313,"receipt":"2017-01-11T17:16:18.952Z","payer":"Chevalerias","bank":null,"details":null}],"invoiceIds":[]}]'), 'fe6c8f922d12', 3),
  (jsonb('[]'), jsonb('[{"created":"2025-07-10T15:53:42.404Z","season":"2025/2026","certificates":{"00453a0ae07e":true},"charged":300,"period":"year","details":null,"payments":[{"type":"check","value":300,"receipt":"2025-07-10T15:53:50.802Z","payer":"CORBION","bank":null,"details":null}],"invoiceIds":[]},{"created":"2024-09-09T18:14:50.784Z","season":"2024/2025","certificates":{"00453a0ae07e":true},"charged":300,"period":"year","details":null,"payments":[{"type":"check","value":115,"receipt":"2024-09-09T18:14:55.400Z","payer":"CORBION","bank":null,"details":null},{"type":"check","value":115,"receipt":"2025-01-01T19:14:55.400Z","payer":"CORBION","bank":null,"details":null},{"type":"check","value":70,"receipt":"2025-04-01T18:14:55.400Z","payer":"CORBION","bank":null,"details":""}],"invoiceIds":[]},{"created":"2022-09-07T19:20:03.869Z","season":"2022/2023","certificates":{},"charged":495,"period":"year","details":null,"payments":[{"type":"check","value":495,"receipt":"2022-09-07T19:20:11.079Z","payer":"CORBION","bank":"EN COUPLE AVEC GRIGIS CAMILLE","details":"1H+1H30"}],"invoiceIds":[]},{"created":"2021-11-17T18:52:55.874Z","season":"2021/2022","certificates":{},"charged":99,"period":"quarter","details":null,"payments":[{"type":"check","value":54,"receipt":"2021-11-17T18:53:04.279Z","payer":"CORBION","bank":"DEBUT 17/11","details":"DONC PRORATA"},{"type":"check","value":99,"receipt":"2022-01-12T17:42:35.093Z","payer":"CORBION","bank":"NE FERA PEUT ETRE PAS 3EME","details":null}],"invoiceIds":[]},{"created":"2020-09-04T13:49:58.768Z","season":"2020/2021","certificates":{"00453a0ae07e":true},"charged":491,"period":"year","details":null,"payments":[{"type":"check","value":491,"receipt":"2020-09-04T13:50:08.110Z","payer":"CORBION","bank":null,"details":null}],"invoiceIds":[]},{"created":"2019-09-13T14:24:32.918Z","season":"2019/2020","certificates":{"00453a0ae07e":true},"charged":182,"period":"quarter","details":null,"payments":[{"type":"check","value":99,"receipt":"2019-09-12T14:24:42.785Z","payer":"CORBION","bank":null,"details":null},{"type":"check","value":99,"receipt":"2020-01-01T15:24:42.785Z","payer":"CORBION","bank":null,"details":null},{"type":"check","value":99,"receipt":"2020-04-01T14:24:42.785Z","payer":"CORBION","bank":null,"details":null},{"type":"check","value":83,"receipt":"2019-09-17T14:24:42.785Z","payer":"CORBION","bank":null,"details":null},{"type":"check","value":83,"receipt":"2020-01-01T15:24:42.785Z","payer":"CORBION","bank":null,"details":null},{"type":"check","value":83,"receipt":"2020-04-01T14:24:42.785Z","payer":"CORBION","bank":null,"details":null}],"invoiceIds":[]}]'), 'e4fb35de0f62', 14),
  (jsonb('[]'), jsonb('[{"created":null,"season":"2012/2013","certificates":{"004c9f991e4c":false},"charged":0,"period":"year","details":null,"payments":[],"invoiceIds":[]}]'), 'bc2ce47d943a', 5),
  (jsonb('[]'), jsonb('[]'), '079971a60cb1', 5),
  (jsonb('[]'), jsonb('[{"created":"2025-09-06T09:22:18.766Z","season":"2025/2026","certificates":{},"charged":450,"period":"year","details":null,"payments":[{"type":"check","value":90,"receipt":"2025-10-01T09:22:24.381Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":90,"receipt":"2025-11-01T10:22:27.188Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":90,"receipt":"2025-12-01T10:22:30.148Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":90,"receipt":"2026-01-01T10:22:33.285Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":90,"receipt":"2026-02-01T10:22:37.429Z","payer":"AGNELOT","bank":null,"details":null}],"invoiceIds":[]},{"created":"2024-06-28T12:46:13.862Z","season":"2024/2025","certificates":{"0098ddd350e0":true},"charged":940,"period":"year","details":null,"payments":[{"type":"check","value":184,"receipt":"2024-06-28T12:46:22.205Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":184,"receipt":"2024-06-28T12:46:30.917Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":184,"receipt":"2024-06-28T12:46:37.647Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":184,"receipt":"2024-06-28T12:46:42.414Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":184,"receipt":"2024-06-28T12:46:49.935Z","payer":"AGNELOT","bank":null,"details":"detruit arret TD2"},{"type":"traveler","value":20,"receipt":"2024-06-28T12:46:54.334Z","payer":"AGNELOT","bank":null,"details":null}],"invoiceIds":[]},{"created":"2023-06-29T14:23:45.390Z","season":"2023/2024","certificates":{"0098ddd350e0":true},"charged":716,"period":"year","details":null,"payments":[{"type":"traveler","value":100,"receipt":"2023-06-29T14:23:55.345Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":154,"receipt":"2023-09-01T14:24:06.820Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":154,"receipt":"2023-10-01T14:24:19.771Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":154,"receipt":"2023-11-01T15:24:33.010Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":154,"receipt":"2023-12-01T15:24:53.632Z","payer":"AGNELOT","bank":null,"details":null}],"invoiceIds":[]},{"created":"2022-09-07T18:52:55.708Z","season":"2022/2023","certificates":{},"charged":110,"period":"quarter","details":null,"payments":[{"type":"check","value":110,"receipt":"2022-09-07T18:53:03.810Z","payer":"LAURIANE","bank":null,"details":null},{"type":"check","value":110,"receipt":"2023-01-01T14:29:22.247Z","payer":"AGNELOT","bank":null,"details":null},{"type":"check","value":110,"receipt":"2023-04-01T13:29:22.247Z","payer":"AGNELOT","bank":null,"details":null}],"invoiceIds":[]}]'), '4b7f945202cb', 10),
  (jsonb('[]'), jsonb('[{"created":"2018-09-04T13:37:05.479Z","season":"2018/2019","certificates":{},"charged":254,"period":"year","details":null,"payments":[{"type":"check","value":254,"receipt":"2018-07-01T13:37:15.444Z","payer":"LAUGIER","bank":null,"details":null}],"invoiceIds":[]}]'), '67fe1f5402a3', 2)`)

	db.exec(`
INSERT INTO dancer (created, title, firstname, lastname, cellphone, email, birth, id, addressId, cardId, _v) VALUES
	('2016-10-05T11:45:58.682Z', 'Mme', 'Leona', 'Lika', '0675718640', 'adelinalika@hotmail.com', '2009-08-16T22:00:00.000Z', '0006b11481cf', '6f1f21897fe6', 'd292733a4246', 2),
	('2023-09-04T14:12:23.796Z', 'Mlle', 'MAXINE', 'NAZARET', '0625300536', 'aureliacalistri@gmail.com', '2018-05-06T22:00:00.000Z', '0026c924cbd7', '0e5c70835a2e', '7396a6525739' ,4),
	('2023-09-04T14:10:52.727Z', 'Mlle', 'ROMY', 'NAZARET', '0625300536', 'aureliacalistri@gmail.com', '2015-11-07T23:00:00.000Z', '519ff5f922cc', '0e5c70835a2e', '7396a6525739', 4),
	('2016-10-11T16:13:07.529Z', 'M.', 'Laurence', 'Chevalerias', '0770428726', 'laurence.chevalerias@hotmail.fr', '1989-03-19T23:00:00.000Z', '002a17ba0fce', '70f84cf40958', 'fe6c8f922d12', 3),
	('2016-10-11T16:15:07.583Z', 'M.', 'Sebastien', 'Pruvost', '0668835652', 'sebastien.pruvost@hotmail.fr', '1982-01-14T23:00:00.000Z', 'd1009c3902cf', '70f84cf40958', 'fe6c8f922d12', 3),
	('2019-09-13T14:22:47.199Z', 'Mlle', 'LORY', 'CORBION', '0647404945', 'corbion.lory@gmail.com', '1998-12-25T23:00:00.000Z', '00453a0ae07e', '095d17c43a77', 'e4fb35de0f62', 7),
	('2013-09-02T10:23:29.405Z', 'Mlle', 'Elyä', 'Ouattara',null, 'yainaithembela@hotmail.fr', '2003-12-31T23:00:00.000Z', '004c9f991e4c', 'ca2f55e23d4a', 'bc2ce47d943a', 5),
	('2013-09-02T10:23:42.152Z', 'Mlle', 'Alison', 'Blaszczyk', '625152824',null, '1992-12-31T23:00:00.000Z', '00764ebfbf2b', '9267b765d193','079971a60cb1', 5),
	('2022-09-07T18:51:35.423Z', 'Mme', 'LAURIANE', 'AGNELOT', '0625906470', 'laurianea48@gmail.com', '1999-07-02T22:00:00.000Z', '0098ddd350e0', 'f131d7a9302d','4b7f945202cb', 9),
	('2018-09-04T13:35:04.452Z', 'Mlle', 'MAEVA', 'FARHAT', '0658145873', 'sonia.laugier@laposte.net', '2006-07-19T13:36:03.260Z', '00b200720f1d', 'b262a9c7d050','67fe1f5402a3', 2)`)
}
