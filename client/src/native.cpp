#include "native.h"
#include <QDebug>
#include <QTranslator>

#ifdef ANDROID
#include <QtAndroidExtras/QAndroidJniObject>
#include <QAndroidJniEnvironment>
#endif

#include "robot_base.h"
#include "lookup_thread.h"
#include "phonenumber.h"
#include "bots.h"
#include "blocking.h"
#include "blocks.h"

// native translations

#ifdef ANDROID
static void jvIncomingNumber(JNIEnv *env, jobject thiz, jstring number) {
    Q_UNUSED(thiz)

    QString nr;
    if(number != NULL) {
        nr = env->GetStringUTFChars(number, NULL);
        qDebug() << "incoming!" << nr;
    } else {
        qDebug() << "number is hidden";
    }

    QMetaObject::invokeMethod(Native::Instance(), "onIncomingCall", Qt::QueuedConnection, Q_ARG(QString, nr));
}

static void jvSetNetwork(JNIEnv *env, jobject thiz, jint mcc, jint mnc) {
    Q_UNUSED(env)
    Q_UNUSED(thiz)

    qDebug() << "jvSetNetwork" << mcc << mnc;
    QMetaObject::invokeMethod(Native::Instance(), "setNetwork", Qt::QueuedConnection, Q_ARG(int, mcc), Q_ARG(int, mnc));
}

static void jvPostLogin(JNIEnv *env, jobject thiz, jint botId, jstring success_tag, jstring url, jstring html) {
    Q_UNUSED(env)
    Q_UNUSED(thiz)

    qDebug() << "jvCookieSync" << botId;
    QString successTag = env->GetStringUTFChars(success_tag, NULL);
    QString loginUrl = env->GetStringUTFChars(url, NULL);
    QString loginHtml = env->GetStringUTFChars(html, NULL);

    QMetaObject::invokeMethod( Native::Instance(), "postLogin", Qt::QueuedConnection,
                               Q_ARG(int, botId),
                               Q_ARG(QString, successTag),
                               Q_ARG(QString, loginUrl),
                               Q_ARG(QString, loginHtml));

}

static void jvTestNumber(JNIEnv *env, jobject thiz, jint botId, jstring number) {
    QString phoneNr = env->GetStringUTFChars(number, NULL);
    QMetaObject::invokeMethod(Native::Instance(), "onTestLookup",
                              Qt::QueuedConnection, Q_ARG(int, botId), Q_ARG(QString, phoneNr));
}

static void jvGotIntent(JNIEnv *env, jobject thiz, jstring j_target) {
    Q_UNUSED(thiz)

    QString target = env->GetStringUTFChars(j_target, NULL);
    QMetaObject::invokeMethod(Native::Instance(), "onGotIntent",
                              Qt::QueuedConnection, Q_ARG(QString, target));
}

static void jvGotClearIntent(JNIEnv *env, jobject thiz, jint id) {
    Q_UNUSED(thiz)

    QMetaObject::invokeMethod(Native::Instance(), "onGotClearIntent",
                              Qt::QueuedConnection, Q_ARG(int, id));
}

static void jvSetDaemonStatus(JNIEnv *env, jobject thiz, jboolean status) {

    Native::Instance()->m_daemonRunning = status;
    emit Native::Instance()->daemonRunningChanged(status);

}

static void jvBlockLastCaller(JNIEnv *env, jobject thiz) {

    QMetaObject::invokeMethod(Native::Instance(), "onBlockLastCaller",
                              Qt::QueuedConnection);
}

static void jvSaveLastCaller(JNIEnv *env, jobject thiz) {

    QMetaObject::invokeMethod(Native::Instance(), "onSaveLastCaller",
                              Qt::QueuedConnection);
}

static jstring jvTranslate(JNIEnv *env, jobject thiz, jstring j_text) {
    QString text = env->GetStringUTFChars(j_text, NULL);
    QString trText = Native::tr(text.toLocal8Bit());
    return env->NewStringUTF(trText.toUtf8());

    Native::tr("name");
}

static void jvLoginCancel(JNIEnv *env, jobject thiz) {
    emit Native::Instance()->loginCancel();
}

#endif


SINGLETON_CPP(Native)



Native::Native(QObject *parent) : QObject(parent)
{
    rule::initialize();
    qRegisterMetaType<QMap<QString,QString> >("QMap<QString,QString>");
    qRegisterMetaType<QList<int> >("QList<int>");

    return;

    tr("name");
    tr("address");
    tr("country");
    tr("operator");
    tr("email");
    tr("profession");
    tr("telnr");
    tr("category");
    tr("comment");
    tr("status");
    tr("error");
    tr("owner");
    tr("website");
    tr("age");
    tr("ssn");
    tr("marital status");
    tr("organization number");
    tr("vehicles");
    tr("properties");
    tr("company information");
    tr("remarks");

}

void Native::registerServiceMethods() {

#ifdef ANDROID

    qDebug() << "registering native methods";

    JNINativeMethod serviceMethods[] {
        {"incomingCall", "(Ljava/lang/String;)V", (void*) jvIncomingNumber },
        {"testNumber", "(ILjava/lang/String;)V", (void*) jvTestNumber },
        {"setNetwork", "(II)V", (void*) jvSetNetwork },
        {"blockLastCaller", "()V", (void*) jvBlockLastCaller },
        {"saveLastCaller", "()V", (void*) jvSaveLastCaller },
        {"translate", "(Ljava/lang/String;)Ljava/lang/String;", (void*) jvTranslate},
        {"gotClearIntent", "(I)V", (void*) jvGotClearIntent }
    };

    QAndroidJniObject javaClass("com/omnight/phonehook/MyService");
    QAndroidJniEnvironment env;
    jclass objectClass = env->GetObjectClass(javaClass.object<jobject>());


    jint regCount =
    env->RegisterNatives(objectClass,
                         serviceMethods,
                         sizeof(serviceMethods) / sizeof(serviceMethods[0]));

    qDebug() << "registered" << regCount;

    env->DeleteLocalRef(objectClass);

    QAndroidJniObject::callStaticMethod<void>("com/omnight/phonehook/Native",
                                       "nativeReady");

        //public static String getContactName(String phoneNumber) {

    if (env->ExceptionCheck()) {
        // Handle exception here.
        qDebug() << "exception ready!!";
        env->ExceptionDescribe();
        env->ExceptionClear();
    }
#endif

}

void Native::registerGuiMethods() {

#ifdef ANDROID
    {
        JNINativeMethod serviceMethods[] {
            {"postLogin", "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", (void*) jvPostLogin },
            {"loginCancel", "()V", (void*) jvLoginCancel },
            {"onDaemonStatusChange", "(Z)V", (void*) jvSetDaemonStatus },
            {"gotIntent", "(Ljava/lang/String;)V", (void*) jvGotIntent }
        };

        QAndroidJniObject javaClass("com/omnight/phonehook/MyService");
        QAndroidJniEnvironment env;
        jclass objectClass = env->GetObjectClass(javaClass.object<jobject>());

        jint regCount =
        env->RegisterNatives(objectClass,
                             serviceMethods,
                             sizeof(serviceMethods) / sizeof(serviceMethods[0]));

        qDebug() << "registered" << regCount;
        env->DeleteLocalRef(objectClass);
    }

    QAndroidJniObject::callStaticMethod<void>("com/omnight/phonehook/Native",
                                       "nativeGuiReady");

#endif
}


void Native::startLogin(int bot_id, QString login_data) {
#ifdef ANDROID
    QAndroidJniObject::callStaticMethod<void>("com/omnight/phonehook/Native",
                "startLogin", "(ILjava/lang/String;)V",
                (jint)bot_id,
                QAndroidJniObject::fromString(login_data).object<jstring>()
    );
#endif

}

QString Native::getContactFromNumber(QString number) {

#ifdef ANDROID
    QAndroidJniObject cnStr =
    QAndroidJniObject::callStaticObjectMethod("com/omnight/phonehook/Native",
                "getContactName", "(Ljava/lang/String;)Ljava/lang/String;",
                QAndroidJniObject::fromString(number).object<jstring>()
    );

    if(!cnStr.isValid()) return NULL;

    QString contact = cnStr.toString();
    return contact;
#endif

}

QString Native::contactIdFromNumber(QString number) {

#ifdef ANDROID
    QAndroidJniObject ret =
    QAndroidJniObject::callStaticObjectMethod("com/omnight/phonehook/Native",
                "contactIdFromNumber", "(Ljava/lang/String;)Ljava/lang/String;",
                QAndroidJniObject::fromString(number).object<jstring>()
    );    

    return ret.toString();
#endif

}

void Native::setDaemonRunning(bool daemonRunning)  {
#ifdef ANDROID
    QAndroidJniObject::callStaticMethod<void>("com/omnight/phonehook/Native",
                                       "setDaemonRunning", "(Z)V", daemonRunning);

    QAndroidJniEnvironment env;
    if (env->ExceptionCheck()) {
        // Handle exception here.
        qDebug() << "exceptioN!!";
        env->ExceptionDescribe();
        env->ExceptionClear();
    }
#endif

}

bool Native::daemonRunning() {
    return m_daemonRunning;
}

bool Native::isServiceRunning() {

#ifdef ANDROID

    jboolean isRunning =
    QAndroidJniObject::callStaticMethod<jboolean>("com/omnight/phonehook/Native",
                                       "isServiceRunning",
                                       "()Z");


    return isRunning;

#else
    return false;
#endif
}

void Native::setNetwork(int mcc, int mnc) {
    this->mcc = mcc;
    this->mnc = mnc;
}

int Native::getMcc() {
    return mcc;
}

int Native::getMnc() {
    return mnc;
}

void Native::onIncomingCall(QString number) {
    qDebug() << "getting incoming from " << number;

    phonenumber pn(number,
                   phonenumber::mobilecc_to_iso32662( getMcc() ),
                   QString::number( getMnc()  ));

    m_lastNumber = pn;

    if(blocking::Instance()->preCheckBlock(m_lastNumber) ) {
        return;
    }

    qDebug() << "check settings";

    QSqlQuery qs;
    qs.exec("SELECT key, value FROM setting");

    bool activateOnSms = false, activateOnlyUnknown = true, enableRoaming = false;

    while(qs.next()) {
        if(qs.value("key").toString() == "activate_only_unknown")
            activateOnlyUnknown = (qs.value("value").toString() == "true");

        if(qs.value("key").toString() == "activate_on_sms")
            activateOnSms = (qs.value("value").toString() == "true");

        if(qs.value("key").toString() == "enable_roaming")
            enableRoaming = (qs.value("value").toString() == "true");
    }


    if(number == "") {
        qDebug() << "ignore hidden number";
        return;
    }

    if(activateOnlyUnknown) {
        QString contactName = getContactFromNumber(number);

        if(contactName != NULL) {
            qDebug() << "found existing contact with name " << contactName;
            return ;
        }
    }

    qDebug() << pn.number_local << pn.number_international;

    //dbus_adapter::Instance()->set_lookupState("activate:lookup");   
    sendCommand("stateChange", "activate:lookup");

    lookup_thread *lt = new lookup_thread();

    m_lastLookupResult = QJsonArray();

    connect(lt, SIGNAL(gotResult(lookup_thread*,QJsonArray)), this, SLOT(lookupResult(lookup_thread*,QJsonArray)));
    connect(lt, SIGNAL(gotResult(lookup_thread*,QJsonArray)), this, SLOT(lookupResult2(lookup_thread*,QJsonArray)));

    QList<int> bots;
    lt->start(pn, bots);
}

void Native::lookupResult(lookup_thread *sender, QJsonArray result) {
    Q_UNUSED(result)
    if(blocking::Instance()->checkAutoBlock(m_lastNumber)) {
        qDebug() << "disconnecting signal" << sender;
        disconnect(sender, SIGNAL(gotResult(lookup_thread*, QJsonArray)), this, SLOT(lookupResult(lookup_thread*, QJsonArray)));
    }
}

void Native::lookupResult2(lookup_thread *sender, QJsonArray result) {
    Q_UNUSED(sender)
    foreach(auto r, result) {
        m_lastLookupResult.append(r);
    }
}

void Native::onTestLookup(int botId, QString number) {
    //dbus_adapter::Instance()->set_lookupState("activate:lookup");
    sendCommand("stateChange", "activate:lookup");

    qDebug() << "testLookup DBG" << botId << number;

    lookup_thread *lt = new lookup_thread();

    QList<int> bots;
    if(botId != 0)
        bots << botId;

    phonenumber pn(number,
                   phonenumber::mobilecc_to_iso32662( getMcc() ),
                   QString::number( getMnc()  ));

    lt->start(pn, bots);
}


bool Native::testNumber(int botId, QString number) {
#ifdef ANDROID
    jboolean result =
    QAndroidJniObject::callStaticMethod<jboolean>(
        "com/omnight/phonehook/Native",
        "testNumber",
        "(ILjava/lang/String;)Z",
        botId,
        QAndroidJniObject::fromString(number).object<jstring>());

    return result;
#else
    return false;
#endif
}


void Native::sendCommand(QString cmd, QString data) {

    qDebug() << "sending command" << cmd << data;

#ifdef ANDROID
    jboolean result =
    QAndroidJniObject::callStaticMethod<jboolean>(
        "com/omnight/phonehook/Native",
        "sendCommand",
        "(Ljava/lang/String;Ljava/lang/String;)Z",
        QAndroidJniObject::fromString(cmd).object<jstring>(),
        QAndroidJniObject::fromString(data).object<jstring>());


    QAndroidJniEnvironment env;
    if (env->ExceptionCheck()) {
        // Handle exception here.
        qDebug() << "exceptioN!!";
        env->ExceptionDescribe();
        env->ExceptionClear();
    }

    qDebug() << "sendCommand result" << result;
#endif


}

QJsonArray Native::getContacts() {

    QJsonArray contacts;

#ifdef ANDROID
    QAndroidJniObject result =
    QAndroidJniObject::callStaticObjectMethod<jstring>(
        "com/omnight/phonehook/Native",
        "getContacts");

    QAndroidJniEnvironment env;
    if (env->ExceptionCheck()) {
        qDebug() << "exception!!";
        env->ExceptionDescribe();
        env->ExceptionClear();
    }

    contacts = QJsonDocument::fromJson(result.toString().toUtf8()).array();
#endif

    return contacts;

}

void Native::postLogin(int bot_id, QString success_tag, QString login_url, QString login_html) {

    // open cookiez db
    // /home/nemo/.local/share/phonehook/phonehook/.QtWebKit/cookies.db
    // .../app_webview/Cookies


    // table|cookies|cookies|2|CREATE TABLE cookies (cookieId VARCHAR PRIMARY KEY, cookie BLOB)
    // index|sqlite_autoindex_cookies_1|cookies|3|

    qDebug() << "copy cookies";

    QString cookies_db_path = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation).at(0) + "/../app_webview/Cookies";

    if(!QFile::exists(cookies_db_path)) {
        emit loginResult(false, -1);
        return;
    }

    QSqlDatabase cookieDb = QSqlDatabase::addDatabase("QSQLITE", "cookies");

    cookieDb.setDatabaseName(cookies_db_path);
    if(!cookieDb.open()) {
        qDebug() << "failed to open cookie db";
        emit loginResult(false, -2);
        return;
    }


    QSqlQuery getCookiesQuery(R"(
        SELECT host_key, name, value, path, expires_utc FROM cookies;
    )", cookieDb);

    getCookiesQuery.exec();

    while(getCookiesQuery.next()) {
        // get cookie text from BLOB
        //QString cookieText = QString::fromUtf8( getCookiesQuery.value("cookie").value<QByteArray>() );

        // split
        // SSID=A...9; secure; HttpOnly; expires=Wed, 05-Jul-2017 16:56:19 GMT; domain=.google.com; path=/
        //QStringList parts = cookieText.split(";");
/*
        bot_id INTEGER REFERENCES BOT(id) ON DELETE CASCADE,
        key TEXT,
        domain TEXT,
        path TEXT,
        expire TEXT,
        value TEXT*/

        QString key = QString::fromUtf8( getCookiesQuery.value("name").value<QByteArray>() );
        QString value = QString::fromUtf8( getCookiesQuery.value("value").value<QByteArray>() );
        QString domain = QString::fromUtf8( getCookiesQuery.value("host_key").value<QByteArray>() );
        QString path = QString::fromUtf8( getCookiesQuery.value("path").value<QByteArray>() );
        QString expires = QString::fromUtf8( getCookiesQuery.value("expires_utc").value<QByteArray>() );

        QSqlQuery clearOldCookie(R"(
            DELETE FROM bot_cookie_cache WHERE bot_id=? AND key=? AND domain=?;
        )");

        clearOldCookie.addBindValue(bot_id);
        clearOldCookie.addBindValue(key);
        clearOldCookie.addBindValue(domain);

        clearOldCookie.exec();

        QSqlQuery checkExistingCookie(R"(
            INSERT INTO bot_cookie_cache(bot_id,key,value,domain,path,expire)
            VALUES(?,?,?,?,?,?);
        )");


        if(expires == "0") {
            expires = "session";
        } else {
            QDateTime expireDate = QDateTime::fromString(expires, "ddd, dd-MMM-yyyy HH:mm:ss 'GMT'");
            expireDate.setTimeSpec(Qt::UTC);
            expires = expireDate.toString("yyyy-MM-dd HH:mm:ss");
        }
        checkExistingCookie.addBindValue(bot_id);
        checkExistingCookie.addBindValue(key);
        checkExistingCookie.addBindValue(value);
        checkExistingCookie.addBindValue(domain);
        checkExistingCookie.addBindValue(path);
        checkExistingCookie.addBindValue(expires);
        checkExistingCookie.exec();

        qDebug() << "Cookie: " + key+"="+QUrl::toPercentEncoding(value)+"; Path=" + path + "; Domain=" + domain + "; Expires=" + expires+";";
        //qDebug() << bot_id << key << value << domain << path << expires;

    }

    cookieDb.close();
    cookieDb.removeDatabase("cookies");

    // run post-login script
    if(success_tag != "") {
        lookup_thread *lt = new lookup_thread();

        QList<int> bots;
        bots << bot_id;

        QMap<QString,QString> params;
        params["tagWanted"] = success_tag;
        params["login_http"] = login_html;
        params["login_url"] = login_url;

        qDebug() << "login_http" << login_html;
        qDebug() << "login_url" << login_url;

        lt->start(params, bots);

        connect(lt, SIGNAL(gotResult(lookup_thread*,QJsonArray)), this, SLOT(loginSuccessBotResult(lookup_thread*,QJsonArray)));

    } else {
        emit loginResult(true, 0);
    }

}

void Native::loginSuccessBotResult(lookup_thread*, QJsonArray) {
    emit loginResult(true, 0);
}

void Native::launchMaps(QString address) {
#ifdef ANDROID
    QAndroidJniObject::callStaticMethod<void>(
        "com/omnight/phonehook/Native",
        "launchMaps",
        "(Ljava/lang/String;)V",
        QAndroidJniObject::fromString(address).object<jstring>());
#endif
}

void Native::launchNumber(QString number) {
#ifdef ANDROID
    QAndroidJniObject::callStaticMethod<void>(
        "com/omnight/phonehook/Native",
        "launchNumber",
        "(Ljava/lang/String;)V",
        QAndroidJniObject::fromString(number).object<jstring>());
#endif
}

void Native::launchAddContact(QString name, QString address, QString number, QString url) {
#ifdef ANDROID
    QAndroidJniObject::callStaticMethod<void>(
        "com/omnight/phonehook/Native",
        "launchAddContact",
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
        QAndroidJniObject::fromString(name).object<jstring>(),
        QAndroidJniObject::fromString(address).object<jstring>(),
        QAndroidJniObject::fromString(number).object<jstring>(),
        QAndroidJniObject::fromString(url).object<jstring>());
#endif
}


void Native::hangUp() {
#ifdef ANDROID
    QAndroidJniObject::callStaticMethod<void>(
        "com/omnight/phonehook/Native",
        "disconnectCall");
#endif
}


QString Native::contactName(QString contactId) {

    if(contactId == "") return "";

    if(contactNameCache.contains(contactId))
        return contactNameCache[contactId];

#ifdef ANDROID
    QAndroidJniObject name =
    QAndroidJniObject::callStaticObjectMethod(
        "com/omnight/phonehook/Native",
        "getContactNameById",
        "(Ljava/lang/String;)Ljava/lang/String;",
        QAndroidJniObject::fromString(contactId).object<jstring>());

    QAndroidJniEnvironment env;
    if (env->ExceptionCheck()) {
        // Handle exception here.
        qDebug() << "exceptioN!!";
        env->ExceptionDescribe();
        env->ExceptionClear();
    }

    return name.toString();
#endif

    return "--";

}

QJsonArray Native::getCallLog() {
#ifdef ANDROID
    return m_callLog;
#else
    return QJsonArray();
#endif
}

QString Native::getCallLogType() {
    return m_callLogType;
}

void Native::setCallLogType(QString type) {
    m_callLogType = type;
    m_callLog = QJsonArray();
    m_hasMoreCallLogs = true;

    emit callLogTypeChanged(m_callLogType);
    emit callLogChanged(m_callLog);
    emit hasMoreCallLogsChanged(m_hasMoreCallLogs);
}

bool Native::moreCallLogs() {
#ifdef ANDROID
    QAndroidJniObject results =
    QAndroidJniObject::callStaticObjectMethod(
        "com/omnight/phonehook/Native",
        "getCallLog",
        "(Ljava/lang/String;I)Ljava/lang/String;",
        QAndroidJniObject::fromString(m_callLogType).object<jstring>(),
        m_callLog.count());


    QJsonDocument result = QJsonDocument::fromJson(results.toString().toUtf8());

    if(result.array().count() == 0) {
        m_hasMoreCallLogs = false;
        emit hasMoreCallLogsChanged(m_hasMoreCallLogs);
        return false;
    }

    foreach(auto r, result.array()) {
        m_callLog.append(r);
    }

    emit callLogChanged(m_callLog);
    emit hasMoreCallLogsChanged(m_hasMoreCallLogs);
    return true;
#else
    return false;
#endif

}

bool Native::hasMoreCallLogs() {
    return m_hasMoreCallLogs;
}


void Native::onBlockLastCaller() {

    QString name;

    foreach(auto r, m_lastLookupResult) {

        QJsonObject ro = r.toObject();

        if(ro["stitle"] == "name" && name == "") {
            name = ro["value"].toString();
        }
    }

    if(m_lastNumber.number_local != "") {
        if(name == "") name = m_lastNumber.number_local;
        blocks b;
        b.addManualBlock(name, m_lastNumber.number_international, false);
        if(blocking::Instance()->checkManualBlock(m_lastNumber))
            blocking::Instance()->hangup();
    }

}

void Native::onSaveLastCaller() {

    QString name, address;

    foreach(auto r, m_lastLookupResult) {

        QJsonObject ro = r.toObject();

        if(ro["stitle"] == "name" && name == "") {
            name = ro["value"].toString();
        }

        if(ro["stitle"] == "address" && address == "") {
            address = ro["value"].toString();
        }
    }

    if(m_lastNumber.number_local != "") {
        launchAddContact(name, address, m_lastNumber.number_international, "");
    }

}

void Native::createNotification(int id, QString title, QString message, QString bigMessage, QString target) {

#ifdef ANDROID
    QAndroidJniObject::callStaticMethod<void>(
        "com/omnight/phonehook/Native",
        "createNotification",
        "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
        id,
        QAndroidJniObject::fromString(title).object<jstring>(),
        QAndroidJniObject::fromString(message).object<jstring>(),
        QAndroidJniObject::fromString(bigMessage).object<jstring>(),
        QAndroidJniObject::fromString(target).object<jstring>());
#endif

}

void Native::onGotIntent(QString target) {

    m_intentTarget = target;
    emit intentTargetChanged(m_intentTarget);
}


void Native::onGotClearIntent(int id) {
    if(id == 2) {
        blocks b;
        b.setAllViewed();
    }
}

QString Native::getIntentTarget() {
    return m_intentTarget;
}

QString Native::getCountry() {
#ifdef ANDROID
    QAndroidJniObject result =
    QAndroidJniObject::callStaticObjectMethod(
        "com/omnight/phonehook/Native",
        "getOperatorCountry",
        "()Ljava/lang/String;");

    return result.toString();
#endif
}
