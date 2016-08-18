#include "blocking.h"
#include "db.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>
#include "setting.h"
#include "native.h"


SINGLETON_CPP(blocking)

blocking::blocking(QObject *parent) :
    QObject(parent)
{

}

bool blocking::checkManualBlock(phonenumber number) {

    QSqlQuery checkManualBlock;

    checkManualBlock.prepare(R"(
        SELECT * FROM block
        WHERE (? like REPLACE(number, '*','%'))
           OR (? like REPLACE(number, '*','%'));
    )");


    checkManualBlock.addBindValue(number.number_local);
    checkManualBlock.addBindValue(number.number_international);

    checkManualBlock.exec();

    if(checkManualBlock.next()) {
        QSqlQuery addBlockHistory(R"(
          INSERT INTO block_history(block_id,number)
          VALUES(?,?)
        )");
        addBlockHistory.addBindValue(checkManualBlock.value("id").toInt());
        addBlockHistory.addBindValue(number.number_international);
        addBlockHistory.exec();
        return true;
    }

    return false;

}


bool blocking::checkAutoBlock(phonenumber number) {
    QSqlQuery autoBlockQuery(R"(
        SELECT block.id FROM block JOIN bot_result_cache ON block.bot_id = bot_result_cache.bot_id
        WHERE bot_result_cache.telnr IN (?,?) AND bot_result_cache.block = 1
    )");

    autoBlockQuery.addBindValue(number.number_local);
    autoBlockQuery.addBindValue(number.number_international);

    if(!autoBlockQuery.exec())
        qDebug() << "check block error" << autoBlockQuery.lastError();

    if(autoBlockQuery.next()) {

        hangup();

        QSqlQuery addBlockHistory(R"(
            INSERT INTO block_history(block_id,number)
            VALUES(?,?)
        )");
        addBlockHistory.addBindValue(autoBlockQuery.value("id").toInt());
        addBlockHistory.addBindValue(""+number.number_international);
        addBlockHistory.exec();

        createNotification();

        return true;
    }

    return false;
}

bool blocking::checkContactBlock(phonenumber number) {

    QString id = Native::Instance()->contactIdFromNumber(number.number_international);
    if(id == "") return false;

    QSqlQuery blockedContactsQuery(R"(
        SELECT contact_id FROM block
        WHERE type=1 AND ? LIKE '%' || contact_id || '%'
    )");

    blockedContactsQuery.addBindValue(id);
    blockedContactsQuery.exec();

    if(blockedContactsQuery.first()) {

        id = blockedContactsQuery.value("contact_id").toString();

        QSqlQuery addBlockHistory(R"(
            INSERT INTO block_history(block_id,number)
            SELECT id,? FROM block WHERE contact_id=?
        )");
        addBlockHistory.addBindValue(number.number_international);
        addBlockHistory.addBindValue(id);
        addBlockHistory.exec();

        qDebug() << "blocked! contact id = " << id;

        return true;
    }

    return false;
}

bool blocking::preCheckBlock(phonenumber number) {
    if(checkManualBlock(number) || checkContactBlock(number)) {
        hangup();
        createNotification();
        return true;
    }

    // don't auto-check hidden
    if(number.number_local == "")
        return false;

    return checkAutoBlock(number);

}

void blocking::hangup() {
    Native::Instance()->hangUp();
}

void blocking::createNotification() {
    QString message;

    QSqlQuery getBlockQueryCount;
    getBlockQueryCount.prepare(R"(
        SELECT COUNT(*) cnt FROM block_history WHERE viewed = 0;
    )");

    getBlockQueryCount.exec();
    getBlockQueryCount.next();

    int blockCount = getBlockQueryCount.value("cnt").toInt();

    if(blockCount > 1) {
        message = tr("%1 calls blocked").arg(blockCount);
    }

    QSqlQuery getBlockQuery;
    getBlockQuery.prepare(R"(
        SELECT number, MAX(date), COUNT(*) cnt
        FROM block_history
        WHERE viewed = 0
        GROUP BY number
        ORDER BY MAX(date) DESC;
    )");

    getBlockQuery.exec();

    QString bigText = tr("Blocked calls:") +"\n";

    while(getBlockQuery.next()) {

        auto nr = getBlockQuery.value("number").toString();

        if(nr == "")
            bigText +=  tr("<Hidden Number>");
        else
            bigText += nr;

        if(getBlockQuery.value("cnt").toInt() > 1) {
            bigText += " (" + getBlockQuery.value("cnt").toString() + ")";
        }
        bigText += "\n";

        if(blockCount == 1) {
            message = tr("Blocked call from %1").arg(getBlockQuery.value("number").toString());
            bigText = "";
        }
    }

    Native::Instance()->createNotification(2, "phonehook", message, bigText, "blocks");
}
