#include "db.h"

#include <QDir>
#include <QSqlQuery>
#include <QDebug>
#include <QStandardPaths>

SINGLETON_CPP(db)

db::db(QObject *parent) :
    QObject(parent)
{
    QString dataDir = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation).at(0) + "/.phonehook";
    QDir::home().mkpath(dataDir);

    // local db
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dataDir + "/phonehook.db");
    m_db.open();

    initDbTables();

    m_db.setConnectOptions("foreign_keys = ON");
}


db::~db() {
    m_db.close();
    m_db_contacts.close();
}

void db::initDbTables() {

    QSqlQuery q;
    QDir scriptDir(":/db_script");

    QStringList scriptList = scriptDir.entryList(QStringList("*.sql"), QDir::NoFilter, QDir::Name);

    int currentVersion = 0;
    if(m_db.tables().count() > 0) {
        QSqlQuery getVersionQuery("SELECT * FROM DB_VERSION");
        if(getVersionQuery.next()) {
          currentVersion = getVersionQuery.value(0).toInt();
        }
    }



    foreach(QString u, scriptList) {

        int v = QString(u).replace(".sql", "").toInt();

        if(currentVersion >= v) continue;

        qDebug() << "applying db patch " << u << scriptDir.absoluteFilePath(u);

        QFile script(scriptDir.absoluteFilePath(u));
        script.open(QFile::ReadOnly);
        QString queryText = script.readAll();

        foreach(QString part, queryText.split(";", QString::SkipEmptyParts)) {
            if(part.trimmed().isEmpty()) continue ;
            if(!q.exec( part )) {
                qDebug() << "update failed - " << part;
            }
        }

        script.close();

        if(q.exec("UPDATE DB_VERSION SET version = " + QString::number(v))) {
            qDebug() << "updated to version " << v;
        }

    }

}

QSqlDatabase db::getContactsDb() {
    return m_db_contacts;
}

QSqlDatabase db::getDb() {
    return m_db;
}
