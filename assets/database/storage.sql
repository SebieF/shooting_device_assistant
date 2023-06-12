CREATE TABLE devices(
    id INTEGER PRIMARY KEY,
    name TEXT,
    deviceCategory TEXT,
    customCategoryName TEXT,
    stockKind TEXT
);

CREATE TABLE disciplines(
    id INTEGER PRIMARY KEY,
    name TEXT,
    deviceID INTEGER,
    isConfiguration TEXT,
    configurationName TEXT,
    orderedConfigPosition INTEGER
);

CREATE TABLE settings(
    id INTEGER PRIMARY KEY,
    name TEXT,
    disciplineID INTEGER,
    orderedPosition INTEGER
);

CREATE TABLE settingEntries(
    id INTEGER PRIMARY KEY,
    date TEXT,
    value TEXT,
    lengthMeasure TEXT,
    notes TEXT,
    settingID INTEGER,
    isGeneralImage TEXT
);

CREATE TABLE images(
    id INTEGER PRIMARY KEY,
    settingEntryID INTEGER,
    rotation INTEGER,
    path TEXT
);


