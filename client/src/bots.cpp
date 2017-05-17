#include "bots.h"
#include <QDir>
#include <QDomDocument>
#include <QXmlQuery>
#include <QSqlField>
#include <QXmlResultItems>
#include "lookup_thread.h"
#include "setting.h"
#include <QProcess>
#include "countries.h"
#include <QSqlError>
#include "db.h"
#include <QJsonArray>
#include <QJsonObject>

bots::bots(QObject *parent) :
    QObject(parent)
{

    // enable foreign key support

    m_db = db::Instance()->getDb();

    m_db.exec("PRAGMA foreign_keys = ON;");

    if(m_db.tables().count() > 0) {
        QSqlQuery getVersionQuery("SELECT * FROM DB_VERSION");
        if(getVersionQuery.next()) {
          m_version = getVersionQuery.value(0).toInt();
        }
    }

    connect(&netman, SIGNAL(finished(QNetworkReply*)), this, SLOT(network_response(QNetworkReply*)));

    m_daemonActive = true;

    initBotList();
}

bots::~bots() {
    qDebug() << "~bots";
}

int bots::version() {
    return m_version;
}

void bots::downloadBot(QString file, bool KeepData) {
    QNetworkRequest req;
    QString downloadUrlRoot = setting::get("download_root_url", "https://raw.githubusercontent.com/omnight/phonehook-sources/master/files/");

    req.setUrl(QUrl(downloadUrlRoot + file));
    req.setRawHeader("KeepData", KeepData ? "true" : "false");
    QNetworkReply* rep = netman.get(req);
}



void bots::updateBotData(QVariantMap data) {

    QString updateStr = "UPDATE bot SET ";

    QSqlQuery sq;

    for(QVariantMap::const_iterator iter = data.begin(); iter != data.end(); ++iter) {
        if(iter.key() == "id") continue ;
        updateStr = updateStr + iter.key() + " = ?,";
        //sq.addBindValue( iter.value() );
    }

    // remove last ,
    updateStr = updateStr.left( updateStr.length() - 1 );
    updateStr = updateStr + " WHERE id = ?";

    sq.prepare(updateStr);

    for(QVariantMap::const_iterator iter = data.begin(); iter != data.end(); ++iter) {
        if(iter.key() == "id") continue ;
        sq.addBindValue( iter.value() );
        qDebug() << iter.value();
    }

    sq.addBindValue(data.value("id"));

    qDebug() << data.value("id");


    qDebug() << "update query " << updateStr << sq.exec();

}

void bots::network_response(QNetworkReply *reply) {

    QXmlQuery xq;
    QSqlQuery sq;

    bool KeepData = reply->request().rawHeader("KeepData") == "true" ? true : false;

    if(reply->attribute(QNetworkRequest::HttpStatusCodeAttribute) != 200) {
        emit botDownloadFailure();
        return;
    }

    QString strXml = reply->readAll();

    if(strXml == "") {
        emit botDownloadFailure();
        return;
    }

    xq.setFocus(strXml);

    QString name, revision, description, icon, link, country;
    xq.setQuery("robot/meta/name/string()");
    xq.evaluateTo(&name);
    name = name.trimmed().replace("&amp;","&");

    xq.setQuery("robot/meta/revision/number()");
    xq.evaluateTo(&revision);

    xq.setQuery("robot/meta/description/string()");
    xq.evaluateTo(&description);
    description = description.trimmed().replace("&amp;","&");;

    xq.setQuery("robot/meta/country/string()");
    xq.evaluateTo(&country);
    country = country.trimmed();

    xq.setQuery("robot/meta/icon/string()");
    xq.evaluateTo(&icon);
    icon = icon.trimmed();

    xq.setQuery("robot/meta/link/string()");
    xq.evaluateTo(&link);
    link = link.trimmed().replace("&amp;","&");;

    QXmlResultItems paramList;
    xq.setQuery("robot/meta/param");
    xq.evaluateTo(&paramList);

    QList<QVariantMap> insertBotParams;

    QXmlItem x = paramList.next();

    while(!x.isNull()) {
        if(x.isNode()) {
            QVariantMap param;

            QString key;
            QString title;
            QString type;

            xq.setFocus(x);
            xq.setQuery("./string()");
            xq.evaluateTo(&key);

            xq.setQuery("./@title/data(.)");
            xq.evaluateTo(&title);
            xq.setQuery("./@type/data(.)");
            xq.evaluateTo(&type);


            key = key.trimmed();
            title = title.trimmed();
            type = type.trimmed();

            if(type == "") type = "string";

            param.insert("key", key);
            param.insert("title", title);
            param.insert("type", type);

            insertBotParams.append(param);
        }
        x = paramList.next();
    }


    // evaluate and update tags

    QXmlResultItems sets;
    xq.setFocus(strXml);
    xq.setQuery("robot/set");
    xq.evaluateTo(&sets);

    QStringList tagList;

    while(!sets.next().isNull()) {
        xq.setFocus( sets.current() );
        QString tag;
        xq.setQuery("./@tags/data(.)");
        xq.evaluateTo(&tag);
        tagList.append( tag.split(",") );
    }

    sq.prepare("SELECT id FROM bot WHERE name = ?");
    sq.addBindValue( name );
    sq.exec();

    int existing_id = 0;

    while(sq.next()) {
        existing_id = sq.value("id").toInt();
    }

    sq.finish();



    if(existing_id) {

        sq.prepare("SELECT key, value FROM bot_param WHERE bot_id = ?");
        sq.addBindValue(existing_id);

        sq.exec();

        while(sq.next()) {

            QString key = sq.value("key").toString();
            QString value = sq.value("value").toString();

            for(int i=0; i < insertBotParams.length(); i++) {
                QVariantMap ip = insertBotParams.at(i);
                if(ip.value("key") == key) {
                    ip.insert("value", value);
                    insertBotParams.replace(i, ip);
                }
            }
        }

        sq.finish();

        sq.prepare("DELETE FROM bot_param WHERE bot_id = ?");
        sq.addBindValue(existing_id);

        qDebug() << "deleting old params" <<
                    sq.exec();


        sq.finish();

        sq.prepare("DELETE FROM bot_tag WHERE bot_id = ?");
        sq.addBindValue(existing_id);

        qDebug() << "deleting old tags" <<
                    sq.exec();


        sq.finish();

    }

    if(existing_id) {
        qDebug() << "update";

        sq.prepare("UPDATE BOT SET revision = ?, xml = ?, link = ?, icon = ?, description = ?, country = ? WHERE id = ?");
        sq.addBindValue( revision );
        sq.addBindValue( strXml );
        sq.addBindValue( link );
        sq.addBindValue( icon );
        sq.addBindValue( description );
        sq.addBindValue( country );
        sq.addBindValue( existing_id );


        qDebug() << "bot update " << sq.exec();
        emit botList_changed(&m_botList);
    } else {
        qDebug() << "insert";

        sq.prepare("INSERT INTO BOT (id, name, revision, enabled, xml, link, icon, description, country) VALUES(NULL, ?, ?, 1, ?, ?, ?, ?, ?);");
        sq.addBindValue( name );
        sq.addBindValue( revision );
        sq.addBindValue( strXml );
        sq.addBindValue( link );
        sq.addBindValue( icon );
        sq.addBindValue( description );
        sq.addBindValue( country );


        qDebug() << "bot insert " << sq.exec();

        existing_id = sq.lastInsertId().value<int>();

        m_botList.refresh();

        emit botList_changed(&m_botList);
        emit botList()->count_changed(botList()->rowCount());
    }


    // insert tags
    foreach(QString t, tagList) {
        t = t.trimmed();
        qDebug() << "inserting tag" << t;
        sq.prepare("INSERT INTO bot_tag (bot_id, tag) VALUES(?,?);");
        sq.addBindValue(existing_id);
        sq.addBindValue(t);
        sq.exec();
    }

    // insert login methods

    QXmlResultItems logins;
    xq.setFocus(strXml);
    xq.setQuery("robot/meta/login");
    xq.evaluateTo(&logins);

    sq.prepare("DELETE FROM bot_login WHERE bot_id=?;");
    sq.addBindValue(existing_id);
    sq.exec();

    while(!logins.next().isNull()) {
        sq.prepare(R"(
            INSERT INTO bot_login (bot_id,name,url,login_success_url,login_success_tag)
            VALUES(?,?,?,?,?);
        )");
        sq.addBindValue(existing_id);

        QString v;
        xq.setFocus( logins.current() );
        xq.setQuery("./name/string()");
        xq.evaluateTo(&v);
        sq.addBindValue(v.trimmed().replace("&amp;","&"));

        xq.setFocus( logins.current() );
        xq.setQuery("./url/string()");
        xq.evaluateTo(&v);
        sq.addBindValue(v.trimmed().replace("&amp;","&"));

        xq.setFocus( logins.current() );
        xq.setQuery("./login_success_url/string()");
        xq.evaluateTo(&v);
        sq.addBindValue(v.trimmed().replace("&amp;","&"));

        xq.setFocus( logins.current() );
        xq.setQuery("./login_success_tag/string()");
        xq.evaluateTo(&v);
        sq.addBindValue(v.trimmed());

        sq.exec();

    }

    // insert parameters
    foreach(QVariantMap ip, insertBotParams) {

        qDebug() << "inserting param" << ip;

        sq.prepare("INSERT INTO bot_param (bot_id, key, type, title, value) "
                   "VALUES (?, ?, ?, ?, ?);");

        sq.addBindValue(existing_id);
        sq.addBindValue(ip.value("key") );
        sq.addBindValue(ip.value("type") );
        sq.addBindValue(ip.value("title") );        
        sq.addBindValue(ip.value("value", "") );

        qDebug() << existing_id <<
                    ip.value("key") <<
                    ip.value("title") <<
                    ip.value("value", "");

        qDebug() << "param insert" << sq.exec();

    }

    if(!KeepData) {
        sq.prepare("DELETE FROM bot_response_cache WHERE bot_id=?");
        sq.addBindValue(existing_id);
        qDebug() << "cleared response cache" << sq.exec();

        sq.prepare("DELETE FROM bot_result_cache WHERE bot_id=?");
        sq.addBindValue(existing_id);
        qDebug() << "cleared result cache" << sq.exec();
    }

    emit botDownloadSuccess(existing_id);

}

QVariantMap bots::recordToVariantMap(QSqlRecord r) {
    QVariantMap vm;

    for(int i=0; i < r.count(); i++) {
        QSqlField f = r.field(i);
        vm.insert(f.name(), f.value());
    }

    return vm;

}


QVariantMap bots::getBotDetails(int botId) {

    QSqlQuery sq;

    sq.prepare("SELECT * FROM bot WHERE id = ?");
    sq.addBindValue(botId);
    sq.exec();

    if(sq.next()) {
        return recordToVariantMap(sq.record());
    }

}

void bots::setBotSearchListTag(QString tag) {
    m_botSearchList.setQuery("SELECT bot.id, bot.name FROM bot JOIN bot_tag ON bot.id = bot_tag.bot_id WHERE bot_tag.tag='" + tag + "';");
    emit botSearchList_changed(&m_botSearchList);
}

void bots::setActiveBot(int botId) {

    qDebug() << "setting active bot" << botId;

    m_paramList.setQuery("SELECT * FROM bot_param WHERE title <> '' AND bot_id = " + QString::number(botId) +
                         " ORDER BY CASE WHEN type='password' THEN 1 ELSE 0 END;");
    m_loginList.setQuery("SELECT * FROM bot_login WHERE bot_id = " + QString::number(botId));

    emit paramList_changed(&m_paramList);
    emit loginList_changed(&m_loginList);

}

void bots::setBotParam(int botId, QString key, QString value) {
    QSqlQuery sq;

    sq.prepare("UPDATE bot_param SET value = ? WHERE bot_id = ? AND key = ?;");
    sq.addBindValue(value);
    sq.addBindValue(botId);
    sq.addBindValue(key);
    qDebug() << "update bot param " << sq.exec();
}

void bots::testBot(int botId, QString testNumber) {

/*
    QVariantList args;
    QDBusMessage testcall;
    args.append(testNumber);

    if(botId == 0) {
        testcall =
        QDBusMessage::createMethodCall("com.omnight.phonehook",
                                       "/",
                                       "com.omnight.phonehook",
                                       "testLookup2");
    } else {
        testcall =
        QDBusMessage::createMethodCall("com.omnight.phonehook",
                                       "/",
                                       "com.omnight.phonehook",
                                       "testLookup");
        args.append(botId);
    }

    testcall.setArguments(args);
    QDBusConnection::sessionBus().send(testcall);*/

}


void bots::service_registered(QString serviceName) {
    qDebug() << "registered" << serviceName;

    if(serviceName == "com.omnight.phonehook") {
        m_daemonActive = true;
        emit daemonActive_changed(m_daemonActive);

        // db may have updated?

        QSqlQuery qs;
        qs.exec("SELECT version FROM db_version");
        while(qs.next()) {
            m_version = qs.value("version").toInt();
        }

        initBotList();
    }
}

void bots::initBotList() {
    if(!m_botList.query().isValid())
        m_botList.setQuery("SELECT id, name, revision FROM bot;");
    else
        m_botList.refresh();

    emit botList_changed(&m_botList);
}


void bots::service_unregistered(QString serviceName) {
    qDebug() << "unregistered" << serviceName;
    if(serviceName == "com.omnight.phonehook") {
        m_daemonActive = false;
        emit daemonActive_changed(m_daemonActive);
    }
}

void bots::startDaemon() {
    QProcess p;
    p.startDetached("systemctl", QStringList() << "--user" << "restart" << "phonehook-daemon.service");
}


int bots::botStatusCompare(QString name, int rev) {

    qDebug() << "check" << name << rev;

    QSqlQuery qs;
    qs.prepare("SELECT revision FROM bot WHERE name = ?");
    qs.addBindValue(name);
    qs.exec();

    if(qs.next()) {
        if(rev == qs.value("revision").toInt()) {
            return 1;
        } else
            return 2;
    } else {
        return 0;
    }


}
int bots::getBotId(QString name) {
    QSqlQuery qs;

    qs.prepare("SELECT id FROM bot WHERE name = ?");
    qs.addBindValue(name);

    qs.exec();
    if(qs.next()) {
        return qs.value("id").toInt();
    }

    return -1;
}

bool bots::removeBot(int botId) {
    QSqlQuery qs;

    // delete actual bot

    qs.prepare("DELETE FROM bot WHERE id = ?");       
    qs.addBindValue(botId);
    qs.exec();

    qDebug() << "delete result = " << qs.numRowsAffected();

    bool status = qs.numRowsAffected() > 0;

    m_botList.refresh();
    emit botList_changed(&m_botList);
    emit botList()->count_changed(botList()->rowCount());

    return status;
}

QString bots::getCountryName(QString code) {
    return countries::getCountryNameISO3166(code);
}

void bots::clearCache(int botId) {
    QSqlQuery qs;

    qs.exec("DELETE FROM bot_cookie_cache WHERE bot_id = " + QString::number(botId));
    qs.exec("DELETE FROM bot_response_cache WHERE bot_id = " + QString::number(botId));
    qs.exec("DELETE FROM bot_result_cache WHERE bot_id = " + QString::number(botId));

}

bool bots::hasBlockTag(int botId) {
    QSqlQuery qs("SELECT * FROM bot_tag WHERE bot_id = ? AND tag='block';");
    qs.addBindValue(botId);
    qs.exec();

    return qs.next();
}

bool bots::isBlockSource(int botId) {
    QSqlQuery qs("SELECT * FROM block WHERE bot_id = ? AND type=2;");
    qs.addBindValue(botId);
    qs.exec();

    return qs.next();
}

void bots::setBlockSource(int botId, bool enabled) {

    if(!enabled) {
        QSqlQuery qs("DELETE FROM block WHERE bot_id = ? AND type=2;");
        qs.addBindValue(botId);
        qs.exec();
    } else {
        QSqlQuery qs("INSERT INTO block(type,bot_id) VALUES(2, ?);");
        qs.addBindValue(botId);
        qs.exec();
    }

}

void bots::vCardWrite(QString name, QStringList numbers, QString address) {
    QFile vCardFile("/home/nemo/.phonehook/phonehook.vcf");
    if(vCardFile.open(QIODevice::WriteOnly)) {
        QTextStream stream(&vCardFile);
        stream.setCodec("UTF-8");
        stream << "BEGIN:VCARD" << endl <<
                  "VERSION:3.0" << endl;

        if(!name.isEmpty()) stream << "FN:" << name << endl;
        if(!address.isEmpty()) stream << "ADR:" << address.replace("\r\n", " ").replace("\n", " ").replace("\r", " ") << endl;

        foreach(auto nr, numbers) {
            stream << "TEL:" << nr << endl;
        }

        stream << "END:VCARD";
        stream.flush();
        vCardFile.close();
    }
}

void bots::search(QJsonObject inParams, bool clear, int botId) {

//    qDebug() << "hello!!" << parameters << bots;

    QMap<QString,QString> params;
    m_searchResultNext = QJsonValue();
    emit searchResultNext_changed(m_searchResultNext);

    for(QJsonObject::iterator it = inParams.begin(); it != inParams.end(); ++it) {
        params[it.key()] = it.value().toString();
    }

    QList<int> botInt;
    botInt << botId;

    qDebug() << "search params" << params << "bots" << botInt;

    lookup_thread *lt = new lookup_thread();

    connect(lt, SIGNAL(gotResult(lookup_thread*,QJsonArray)), this, SLOT(gotSearchResults(lookup_thread*,QJsonArray)) );

    connect(lt, SIGNAL(destroyed(QObject*)), this, SLOT(gotSearchFinished()));

    if(clear) {
        m_searchResult = QJsonArray();
        emit searchResult_changed(m_searchResult);
    }

    m_searchResultLoading = true;
    emit searchResultLoading_changed(true);

    lt->start(params, botInt);

}

void bots::gotSearchResults(lookup_thread *thread, QJsonArray data) {
    Q_UNUSED(thread)

    m_searchResultNext = QJsonValue();

    for(int i=0; i < data.count(); i++) {
        if(data.at(i).toObject()["tagname"] == "result")
            m_searchResult.append(data.at(i));
        if(data.at(i).toObject()["tagname"] == "next") {
            m_searchResultNext = data.at(i);
        }
    }

    emit searchResultNext_changed(m_searchResultNext);
    emit searchResult_changed(m_searchResult);

}

void bots::gotSearchFinished() {
    m_searchResultLoading = false;
    emit searchResultLoading_changed(m_searchResultLoading);
}

QJsonArray bots::searchResult() {
    return m_searchResult;
}

QJsonValue bots::searchResultNext() {
    return m_searchResultNext;
}

bool bots::searchResultLoading() {
    return m_searchResultLoading;
}

void bots::clearSetting(QString key) {
    QSqlQuery sq;
    sq.prepare("DELETE FROM setting WHERE key = ?");
    sq.addBindValue(key);

    sq.exec();
}
