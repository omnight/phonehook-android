#ifndef NATIVE_H
#define NATIVE_H

#include <QObject>
#include "phonenumber.h"
#include "macros.h"
#include <QJsonArray>
#include <QMap>

class lookup_thread;

class Native : public QObject
{
    Q_OBJECT

    SINGLETON(Native)

private:
    int mcc=0;
    int mnc=0;

    explicit Native(QObject *parent = 0);

    phonenumber m_lastNumber;
    QMap<QString,QString> contactNameCache;

    QJsonArray m_callLog;
    QJsonArray m_lastLookupResult;
    QString m_callLogType;
    bool m_hasMoreCallLogs;
    QString m_intentTarget;

    Q_PROPERTY(bool daemonRunning READ daemonRunning WRITE setDaemonRunning NOTIFY daemonRunningChanged)
    Q_PROPERTY(QJsonArray contacts READ getContacts)
    Q_PROPERTY(QJsonArray call_log READ getCallLog NOTIFY callLogChanged)
    Q_PROPERTY(QString call_log_type READ getCallLogType WRITE setCallLogType NOTIFY callLogTypeChanged)
    Q_PROPERTY(bool has_more_call_logs READ hasMoreCallLogs NOTIFY hasMoreCallLogsChanged)
    Q_PROPERTY(QString intent_target READ getIntentTarget NOTIFY intentTargetChanged)

public:
    void registerServiceMethods();
    void registerGuiMethods();

    bool m_daemonRunning=false;

    QJsonArray getContacts();

    QJsonArray getCallLog();
    QString getCallLogType();
    bool hasMoreCallLogs();
    QString getIntentTarget();

    void setCallLogType(QString type);
    Q_INVOKABLE bool moreCallLogs();

    Q_INVOKABLE void startLogin(int bot_id, QString login_data);

    Q_INVOKABLE bool isServiceRunning();

    //QString notification() const;

    Q_INVOKABLE void sendCommand(QString cmd, QString data);

    Q_INVOKABLE void setNetwork(int mcc, int mnc);
    Q_INVOKABLE void onIncomingCall(QString number);
    Q_INVOKABLE void onTestLookup(int botId, QString number);
    Q_INVOKABLE void onBlockLastCaller();
    Q_INVOKABLE void onSaveLastCaller();

    Q_INVOKABLE void onGotIntent(QString target);
    Q_INVOKABLE void onGotClearIntent(int id);

    Q_INVOKABLE int getMcc();
    Q_INVOKABLE int getMnc();

    Q_INVOKABLE QString getCountry();

    Q_INVOKABLE void postLogin(int bot_id, QString success_tag, QString login_url, QString login_html);

    Q_INVOKABLE bool testNumber(int botId, QString number);
    Q_INVOKABLE QString getContactFromNumber(QString number);
    Q_INVOKABLE void launchMaps(QString address);
    Q_INVOKABLE void launchNumber(QString number);
    Q_INVOKABLE void launchAddContact(QString name, QString address, QString number, QString url);

    Q_INVOKABLE QString contactName(QString id);
    Q_INVOKABLE QString contactIdFromNumber(QString number);

    Q_INVOKABLE void hangUp();


    Q_INVOKABLE void createNotification(int id, QString title, QString message, QString bigText, QString target);

    Q_INVOKABLE void setDaemonRunning(bool daemonRunning);
    bool daemonRunning();

signals:
    void daemonRunningChanged(bool daemonRunning);
    void callLogChanged(QJsonArray callLog);
    void hasMoreCallLogsChanged(bool hasMoreCallLogs);
    void callLogTypeChanged(QString callLogType);
    void intentTargetChanged(QString intentTarget);

    void loginResult(bool success, int code);
    void loginCancel();

private slots:
    void lookupResult(lookup_thread *sender, QJsonArray result);
    void lookupResult2(lookup_thread *sender, QJsonArray result);
    void loginSuccessBotResult(lookup_thread* thread,QJsonArray data);
    //void updateAndroidNotification();

private:
    QString m_notification;
};

#endif // NATIVE_H
