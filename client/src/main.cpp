#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QSqlDatabase>
#include <QTranslator>
#include <QQuickStyle>


#include "native.h"
#include "db.h"
#include "bots.h"
#include "blocks.h"
#include "auto_update.h"
#include "setting.h"


/*

Get cookies from db:
 select key || '=' || value || ';Domain=' || domain || ';Path=' || path || ';Expires=' || IFNULL(NULLIF(expire, 'session'), '') || ';' from bot_cookie_cache;

Replace:
(?<!Expires=;)\r\n
 * */


int main(int argc, char *argv[])
{
    Native *nat = Native::Instance();

    //QCoreApplication::setLibraryPaths( QStringList() << qgetenv("QT_PLUGIN_PATH") );

    qDebug() << "QT_PLUGIN_PATH" << qgetenv("QT_PLUGIN_PATH");
    qDebug() << "Looking for plugins at path: " << QCoreApplication::libraryPaths();
    qDebug() << "drivers" << QSqlDatabase::drivers();


    QTranslator translator;

    bool bTranslationsLoaded =
            translator.load(QLocale(), QLatin1String("phonehook"), QLatin1String("_"), QLatin1String(":/translations"), ".qm");


    if(qgetenv("DAEMON") == "1") {
        qDebug() << "Daemon starting";

        QCoreApplication app(argc, argv);

        if(bTranslationsLoaded)
            app.installTranslator(&translator);


        nat->registerServiceMethods();
        db::Instance();
        auto_update::Instance();

        return app.exec();
    }

    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);


    QQuickStyle::setStyle("Universal");

    if(bTranslationsLoaded)
        app.installTranslator(&translator);

    QQmlApplicationEngine engine;

    db::Instance();
    bots botDb;
    blocks blocks;

    qDebug() << "GUI starting";
    nat->registerGuiMethods();
    nat->setDaemonRunning(true);

    engine.rootContext()->setContextProperty("_setting", setting::Instance());
    engine.rootContext()->setContextProperty("_native", nat);
    engine.rootContext()->setContextProperty("_bots", &botDb);
    engine.rootContext()->setContextProperty("_blocks", &blocks);
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    return app.exec();
}

