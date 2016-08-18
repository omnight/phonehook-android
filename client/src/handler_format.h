#ifndef HANDLER_FORMAT_H
#define HANDLER_FORMAT_H

#include <QObject>
#include "process_data.h"

class robot_base;


class handler_format : public QObject
{
    Q_OBJECT
public:
    explicit handler_format(robot_base *parent = 0);

    void format(QString method, QString params, process_data *p);

    enum PercentAction {
        PercentEncode,
        PercentDecode
    };

    QString special_format(QString function, QString param);
    QString script_handler(QString script, process_data *p);

    QString percentUrl(QString url, QString encoding, PercentAction action);

private:
    robot_base *owner;

signals:

public slots:

};

#endif // HANDLER_FORMAT_H
