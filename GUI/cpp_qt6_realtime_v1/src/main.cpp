// Mercury XU5 / PE1 native C++17 high-rate TC/TM GUI.
// Qt 6 Widgets + Network; firmware/PL images are never modified by this program.
#include "protocol.hpp"
#include "capture.hpp"
#include "hpu_regs.hpp"
#include <QtCore/QDateTime>
#include <QtCore/QElapsedTimer>
#include <QtCore/QFile>
#include <QtCore/QPointer>
#include <QtCore/QTextStream>
#include <QtCore/QThread>
#include <QtCore/QTimer>
#include <QtCore/QMetaObject>
#include <QtGui/QMouseEvent>
#include <QtGui/QClipboard>
#include <QtGui/QTextDocument>
#include <QtGui/QPainter>
#include <QtGui/QWheelEvent>
#include <QtNetwork/QHostAddress>
#include <QtNetwork/QTcpSocket>
#include <QtNetwork/QUdpSocket>
#include <QtWidgets/QApplication>
#include <QtWidgets/QAbstractItemView>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDialog>
#include <QtWidgets/QDoubleSpinBox>
#include <QtWidgets/QFileDialog>
#include <QtWidgets/QFormLayout>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMessageBox>
#include <QtWidgets/QPlainTextEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QScrollArea>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QSplitter>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QTabWidget>
#include <QtWidgets/QTableWidget>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>
#include <QtWidgets/QAbstractItemView>
#include <QtWidgets/QSizePolicy>
#include <algorithm>
#include <array>
#include <cmath>
#include <functional>
#include <stdexcept>
#include <cstdint>
#include <limits>
#include <memory>
#include <numeric>
#include <optional>
#include <string>
#include <vector>

namespace {
using namespace xu5;
QString sh(std::uint64_t n, int width=2){return "0x"+QString("%1").arg(qulonglong(n),width,16,QChar('0')).toUpper();}
QString stamp(){return QDateTime::currentDateTime().toString("HH:mm:ss");}
QLabel* lbl(QString s){return new QLabel(std::move(s));}
QPushButton* btn(QString s,QObject* context,std::function<void()> f){
    auto* b=new QPushButton(std::move(s));QObject::connect(b,&QPushButton::clicked,context,[f=std::move(f)](){f();});return b;
}
QString fromHex(const Bytes& b){return QString::fromStdString(hex(b));}
int bitCount(unsigned n){int k=0;while(n){k+=int(n&1u);n>>=1;}return k;}
QString frameName(int src){
    if(src==0)return "Spikeulike";
    if(src>=1&&src<=4)return QString("DAC%1").arg(src);
    if(src>=5&&src<=8)return QString("ADC%1").arg(src-4);
    if(src==9)return "HPU Core";
    return "Unknown";
}
QString errorString(const std::exception&e){return QString::fromUtf8(e.what());}
void errorBox(QWidget* parent,const QString& e){QMessageBox::warning(parent,"Mercury XU5",e);}
void addLine(QPlainTextEdit* e,const QString&s){
    if(!e)return; e->appendPlainText(s);
}
void initLog(QPlainTextEdit* log){log->setReadOnly(true);log->document()->setMaximumBlockCount(1000);}
QDoubleSpinBox* dbl(double initial,double min,double max,int decimals=3){
    auto*b=new QDoubleSpinBox;
    b->setDecimals(decimals);b->setRange(min,max);b->setValue(initial);
    b->setKeyboardTracking(false);return b;
}

class TraceWidget : public QWidget {
    std::vector<QPointF> points_,model_;
    QString title_="Waiting for data";
    QString xLabel_="FPGA time (s)";
    double yMax_=2.5;
    bool locked_=false,dragging_=false;
    QPoint dragStart_,dragNow_;
    QRectF view_{0,0,1,2.5};
    QRect plotRect()const{return rect().adjusted(64,29,-15,-48);}
    QRectF autoView()const{
        if(points_.empty())return {0,0,1,std::max(yMax_,0.001)};
        double xmin=points_.front().x(),xmax=xmin;
        for(const auto&p:points_){xmin=std::min(xmin,p.x());xmax=std::max(xmax,p.x());}
        double pad=std::max((xmax-xmin)*0.02,1e-6);
        return {xmin-pad,0.0,std::max(xmax-xmin+2*pad,2e-6),std::max(yMax_,0.001)};
    }
    QPointF toScreen(const QPointF&p,const QRectF&v,const QRect&r)const{
        return {r.left()+(p.x()-v.left())/v.width()*r.width(),
                r.bottom()-(p.y()-v.top())/v.height()*r.height()};
    }
    QPointF fromScreen(const QPoint&p,const QRectF&v,const QRect&r)const{
        return {v.left()+double(p.x()-r.left())/r.width()*v.width(),
                v.top()+double(r.bottom()-p.y())/r.height()*v.height()};
    }
public:
    explicit TraceWidget(QWidget*parent=nullptr):QWidget(parent){
        setMinimumSize(270,155);setSizePolicy(QSizePolicy::Expanding,QSizePolicy::Expanding);
        setMouseTracking(true);
        setToolTip("Drag left mouse button to zoom. Scroll to zoom. Double-click to return to live fit.");
    }
    void setTrace(const std::vector<Sample>& samples,double fullScale,const QString&title,
                  const std::vector<std::uint16_t>&model={}){
        points_.clear();model_.clear();points_.reserve(samples.size());model_.reserve(model.size());
        const double factor=fullScale/4096.0;
        for(const auto& s:samples)points_.emplace_back(s.t,double(s.code)*factor);
        if(model.size()==samples.size()){
            for(std::size_t i=0;i<samples.size();++i)
                model_.emplace_back(samples[i].t,double(model[i])*factor);
        }
        title_=title;yMax_=fullScale;
        if(!locked_)view_=autoView();
        update();
    }
    void setXY(std::vector<QPointF> values,double yMax,const QString&title,const QString&xLabel){
        points_=std::move(values);model_.clear();title_=title;xLabel_=xLabel;yMax_=yMax;
        if(!locked_)view_=autoView();update();
    }
    void clear(){points_.clear();model_.clear();locked_=false;view_={0,0,1,2.5};update();}
    void resetZoom(){locked_=false;view_=autoView();update();}
protected:
    void paintEvent(QPaintEvent*)override{
        QPainter p(this);p.fillRect(rect(),Qt::white);p.setRenderHint(QPainter::Antialiasing,false);
        QRect r=plotRect();if(r.width()<40||r.height()<30)return;
        QRectF v=locked_?view_:autoView();
        p.setPen(QColor(30,40,54));p.drawText(QRect(10,2,width()-20,22),Qt::AlignLeft|Qt::AlignVCenter,
                                             p.fontMetrics().elidedText(title_,Qt::ElideRight,width()-25));
        p.setPen(QPen(QColor(230,235,241),1));
        for(int i=0;i<=4;++i){
            int x=r.left()+r.width()*i/4,y=r.top()+r.height()*i/4;
            p.drawLine(x,r.top(),x,r.bottom());p.drawLine(r.left(),y,r.right(),y);
            p.setPen(QColor(75,85,95));
            double t=v.left()+v.width()*i/4;
            p.drawText(QRect(x-44,r.bottom()+5,88,18),Qt::AlignHCenter,QString::number(t,'g',8));
            double yy=v.top()+v.height()*(4-i)/4;
            p.drawText(QRect(0,y-8,r.left()-7,16),Qt::AlignRight,QString::number(yy,'g',5));
            p.setPen(QColor(230,235,241));
        }
        p.setPen(QPen(QColor(65,80,95),1));p.drawRect(r);
        p.drawText(QRect(r.left(),height()-20,r.width(),16),Qt::AlignCenter,xLabel_);
        p.save();p.setClipRect(r.adjusted(1,1,-1,-1));
        auto paintLine=[&](const std::vector<QPointF>&line,const QColor&c){
            if(line.empty())return;
            QPolygonF poly;poly.reserve(int(line.size()));
            for(const auto&pt:line)poly.append(toScreen(pt,v,r));
            p.setPen(QPen(c,1.3));
            if(poly.size()==1)p.drawEllipse(poly[0],2,2);
            else p.drawPolyline(poly);
        };
        paintLine(points_,QColor(22,111,189));paintLine(model_,QColor(219,99,41));
        p.restore();
        if(dragging_){p.setBrush(QColor(31,111,189,36));p.setPen(QPen(QColor(31,111,189),1,Qt::DashLine));
            p.drawRect(QRect(dragStart_,dragNow_).normalized());}
    }
    void mousePressEvent(QMouseEvent*e)override{
        if(e->button()==Qt::LeftButton && plotRect().contains(e->pos())){
            dragStart_=dragNow_=e->pos();dragging_=true;update();
        }
    }
    void mouseMoveEvent(QMouseEvent*e)override{
        if(dragging_){dragNow_=e->pos();update();}
    }
    void mouseReleaseEvent(QMouseEvent*e)override{
        if(e->button()!=Qt::LeftButton||!dragging_)return;
        dragging_=false;dragNow_=e->pos();
        QRect selection=QRect(dragStart_,dragNow_).normalized().intersected(plotRect());
        if(selection.width()>8&&selection.height()>8){
            QRectF source=locked_?view_:autoView();
            auto a=fromScreen(selection.topLeft(),source,plotRect());
            auto b=fromScreen(selection.bottomRight(),source,plotRect());
            view_=QRectF(QPointF(std::min(a.x(),b.x()),std::min(a.y(),b.y())),
                         QPointF(std::max(a.x(),b.x()),std::max(a.y(),b.y())));
            locked_=true;
        }
        update();
    }
    void mouseDoubleClickEvent(QMouseEvent*)override{resetZoom();}
    void wheelEvent(QWheelEvent*e)override{
        QRect r=plotRect();QPoint pos=e->position().toPoint();if(!r.contains(pos))return;
        QRectF v=locked_?view_:autoView();
        double factor=e->angleDelta().y()>0?0.80:1.25;
        auto pivot=fromScreen(pos,v,r);
        double x0=pivot.x()-(pivot.x()-v.left())*factor;
        double y0=pivot.y()-(pivot.y()-v.top())*factor;
        view_={x0,y0,v.width()*factor,v.height()*factor};locked_=true;update();e->accept();
    }
};

class NetworkWorker : public QObject {
    xu5::Shared& s_;
    QUdpSocket* udp_=nullptr;
    QTcpSocket* tcp_=nullptr;
    QHostAddress remote_;
    quint16 remotePort_=0;
    bool connected_=false;
    std::atomic<bool> linkUp_{false};
    std::string mode_;
    xu5::StreamParser stream_;
    mutable std::mutex statusMutex_;
    QString status_="Disconnected";
    void setStatus(QString s){std::lock_guard<std::mutex>g(statusMutex_);status_=std::move(s);}
    void networkError(QString s){s_.socketErrors.fetch_add(1);linkUp_.store(false);setStatus("ERROR: "+s);s_.logs.push({-1,s.toStdString()});}
    void dispatch(const xu5::Frame&frame,const QByteArray&raw){
        s_.rx.fetch_add(1,std::memory_order_relaxed);
        const int src=frame.source;
        if(frame.kind==Kind::Telemetry){
            s_.lastTmVersion.store(frame.version,std::memory_order_relaxed);
            if(src>=5&&src<=8){s_.adc[std::size_t(src-5)].ingest(frame,s_.tickSeconds.load());}
            else if(src==9){s_.hpu.ingest(frame,s_.tickSeconds.load());}
        }
        if(src>=5&&src<=8 && frame.kind==Kind::Telemetry) {
            if(!logTelemetry_.load() && !logRaw_.load())return;
        }
        if(src==9 && frame.kind==Kind::Telemetry && frame.payload.size()>0 && frame.payload[0]==0x40
           && !logTelemetry_.load() && !logRaw_.load()) return;
        if(frame.kind==Kind::Telemetry && !logTelemetry_.load() && !logRaw_.load())return;
        // Non-ADC echoes and HPU register responses remain visible.
        QString line=QString("[%1] %2 %3 V%4 seq=%5 source=%6 bytes=%7")
            .arg(stamp(),mode_=="UDP"?"UDP":"TCP",frame.kind==Kind::Telemetry?"TM":"TC echo")
            .arg(frame.version).arg(sh(frame.seq)).arg(frameName(src)).arg(qulonglong(raw.size()));
        if(logTelemetry_.load()||logRaw_.load()||frame.kind==Kind::CommandEcho)
            line+=" | "+QString::fromStdString(hex(Bytes(raw.constData(),raw.constData()+raw.size())));
        s_.logs.push({src,line.toStdString()});
    }
    std::atomic<bool> logTelemetry_{false},logRaw_{false};
    void drainUdp(){
        if(!udp_)return;
        // Keep the event-loop responsive to queued outgoing commands, too.
        int count=0;
        while(udp_->hasPendingDatagrams() && count++<2048){
            qint64 length=udp_->pendingDatagramSize();
            if(length<1 || length>16384){
                QByteArray discard(int(std::clamp<qint64>(length,0,16384)),Qt::Uninitialized);
                udp_->readDatagram(discard.data(),discard.size());s_.parseErrors.fetch_add(1);continue;
            }
            QByteArray data(int(length),Qt::Uninitialized);
            QHostAddress sender;quint16 port=0;
            auto got=udp_->readDatagram(data.data(),data.size(),&sender,&port);
            if(got<0){s_.parseErrors.fetch_add(1);continue;}
            if(sender!=remote_ || port!=remotePort_){s_.filtered.fetch_add(1);continue;}
            data.resize(int(got));
            Frame f;
            if(!parseDatagram(reinterpret_cast<const Byte*>(data.constData()),std::size_t(data.size()),f)){
                s_.parseErrors.fetch_add(1);continue;
            }
            dispatch(f,data);
        }
        if(udp_ && udp_->hasPendingDatagrams())
            QTimer::singleShot(0,this,[this](){drainUdp();});
    }
    void drainTcp(){
        if(!tcp_)return;
        int chunks=0;
        while(tcp_->bytesAvailable()>0 && chunks++<2048){
            QByteArray bytes=tcp_->read(4096);
            if(bytes.isEmpty())break;
            std::uint64_t errorCount=0;
            auto frames=stream_.feed(reinterpret_cast<const Byte*>(bytes.constData()),std::size_t(bytes.size()),errorCount);
            if(errorCount)s_.parseErrors.fetch_add(errorCount);
            for(const auto&f:frames){
                auto raw=rebuildRaw(f);
                dispatch(f,QByteArray(reinterpret_cast<const char*>(raw.data()),int(raw.size())));
            }
        }
        if(tcp_ && tcp_->bytesAvailable()>0)
            QTimer::singleShot(0,this,[this](){drainTcp();});
    }
public:
    explicit NetworkWorker(Shared&s):s_(s){}
    QString status()const{std::lock_guard<std::mutex>g(statusMutex_);return status_;}
    bool isLinkUp()const{return linkUp_.load();}
    void setVerbose(bool t,bool r){logTelemetry_.store(t);logRaw_.store(r);}
    void close(){
        connected_=false;linkUp_.store(false);stream_.clear();
        if(udp_){udp_->close();delete udp_;udp_=nullptr;}
        if(tcp_){tcp_->abort();delete tcp_;tcp_=nullptr;}
        setStatus("Disconnected");
    }
    void openUdp(const QString&ip,quint16 port,quint16 local){
        close();mode_="UDP";remotePort_=port;
        if(!remote_.setAddress(ip) || remote_.protocol()!=QAbstractSocket::IPv4Protocol){
            networkError("Invalid board IPv4 address");return;
        }
        udp_=new QUdpSocket(this);
        udp_->setSocketOption(QAbstractSocket::ReceiveBufferSizeSocketOption,8*1024*1024);
        if(!udp_->bind(QHostAddress::AnyIPv4,local)){
            auto msg=udp_->errorString();close();networkError("UDP bind: "+msg);return;
        }
        connect(udp_,&QUdpSocket::readyRead,this,[this](){drainUdp();});
        connect(udp_,&QUdpSocket::errorOccurred,this,[this](QAbstractSocket::SocketError){
            if(udp_) networkError(udp_->errorString());
        });
        connected_=true;linkUp_.store(true);
        setStatus(QString("UDP open PC:%1 -> %2:%3").arg(udp_->localPort()).arg(ip).arg(port));
    }
    void openTcp(const QString&ip,quint16 port){
        close();mode_="TCP";remotePort_=port;
        if(!remote_.setAddress(ip)||remote_.protocol()!=QAbstractSocket::IPv4Protocol){networkError("Invalid board IPv4 address");return;}
        tcp_=new QTcpSocket(this);
        connect(tcp_,&QTcpSocket::connected,this,[this](){connected_=true;linkUp_.store(true);setStatus("TCP connected");});
        connect(tcp_,&QTcpSocket::disconnected,this,[this](){connected_=false;linkUp_.store(false);setStatus("TCP disconnected");});
        connect(tcp_,&QTcpSocket::readyRead,this,[this](){drainTcp();});
        connect(tcp_,&QTcpSocket::errorOccurred,this,[this](QAbstractSocket::SocketError){
            if(tcp_)networkError(tcp_->errorString());
        });
        setStatus(QString("TCP connecting %1:%2").arg(ip).arg(port));
        tcp_->connectToHost(remote_,port);
    }
    void sendPacket(QByteArray packet){
        if(mode_=="UDP"&&udp_&&connected_){
            qint64 n=udp_->writeDatagram(packet,remote_,remotePort_);
            if(n==packet.size())s_.tx.fetch_add(1);
            else networkError("UDP send failed");
        }else if(mode_=="TCP"&&tcp_&&connected_){
            if(tcp_->write(packet)>=0)s_.tx.fetch_add(1);
            else networkError("TCP send failed");
        }else s_.logs.push({-1,"Not connected: outgoing packet rejected"});
    }
};

class MercuryGui;
class AdcPage : public QWidget {
    MercuryGui* owner_;
    int source_;
    Shared& shared_;
    std::array<QCheckBox*,6> pairs_{};
    QComboBox* channel_{};
    QLabel* status_{};
    QPlainTextEdit* log_{};
    struct PlotWindow {QPointer<QDialog> dialog;std::vector<TraceWidget*>plots;std::uint64_t baseline=0;bool recent=false;int channel=0;QPointer<QComboBox>view;};
    QPointer<QDialog>gridWindow_;
    std::vector<TraceWidget*>gridPlots_;
    std::array<PlotWindow,12> singles_;
    std::uint64_t lastCount_=0;
    std::uint64_t lastDrawFrames_=std::numeric_limits<std::uint64_t>::max();
    double lastFullScale_=-1.0;
    int lastVersion_=0;
public:
    AdcPage(MercuryGui*owner,Shared&shared,int source,QWidget*parent=nullptr);
    int source()const{return source_;}
    Byte mask()const{
        Byte mask=0;for(int i=0;i<6;++i)if(pairs_[std::size_t(i)]->isChecked())mask|=Byte(1<<i);
        return mask;
    }
    std::vector<int> selected()const{
        std::vector<int>out;for(int i=0;i<6;++i)if(pairs_[std::size_t(i)]->isChecked()){
            out.push_back(i+1);out.push_back(i+7);
        }return out;
    }
    void sendCommand();
    void openGrid();
    void openSingle(int ch,bool restart);
    void refresh(double fullScale);
    void log(const QString&line){addLine(log_,line);}
    void clearCapture(){shared_.adc[std::size_t(source_-5)].clear();lastCount_=0;
                        lastDrawFrames_=std::numeric_limits<std::uint64_t>::max();}
private:
    void setCombo();
    std::vector<std::uint16_t> reference(int ch,const std::vector<Sample>&raw)const;
};

class MercuryGui : public QMainWindow {
    Shared state_;
    QThread networkThread_;
    NetworkWorker* worker_;
    QComboBox* mode_{};
    QLineEdit* ip_{};
    QSpinBox* port_{},*localPort_{};
    QLabel* connection_{},*counters_{},*tmStatus_{};
    QCheckBox* logTelemetry_{},*logRaw_{};
    QDoubleSpinBox* vref_{},*tick_{};
    QComboBox* adcRange_{};
    QTabWidget* tabs_{};
    QPlainTextEdit* spikeInput_{},*spikeLog_{},*dacLog_{},*hpuLog_{};
    QComboBox* dacChip_{},*dacChan_{},*dacWave_{};
    QDoubleSpinBox *dacFreq_{},*dacAmp_{},*dacClock_{},*dacScale_{},*dacDuty_{};
    QSpinBox* dacSamples_{};
    QCheckBox* dacAuto_{},*dacArm_{},*dacReset_{};
    QPlainTextEdit* dacPreview_{};
    TraceWidget* dacPlot_{};
    std::array<QCheckBox*,8>dacMask_{};
    QTabWidget* adcTabs_{};
    std::array<AdcPage*,4> adcPages_{};
    QTableWidget* regsTable_{},*eventTable_{};
    QLineEdit* hpuAddress_{},*hpuValue_{},*hpuStrobe_{};
    QCheckBox* autoPoll_{};
    QSpinBox* autoPollMs_{};
    QLabel* hpuStatus_{};
    TraceWidget* hpuHistogram_{},*hpuRate_{};
    QTimer* autoPollTimer_{};
    Byte seq_=0;
    int pollIndex_=0;
    bool active_=false;
    QString activeMode_;
    std::uint64_t lastRx_=0;
    qint64 lastCounterMs_=0;
    QElapsedTimer clock_;
    void buildInterface();
    QWidget* buildSpike();
    QWidget* buildDac();
    QWidget* buildAdc();
    QWidget* buildHpu();
    void refreshDac();
    void sendDacLoad();
    void sendDacControl(int cmd);
    void sendHpuRead(Byte addr);
    void sendHpuWrite(Byte addr,std::uint32_t data,Byte strobe);
    void refreshHpu();
    void pollHpu();
    void flushLogs();
    void refreshCounters();
    void refreshPlots();
public:
    MercuryGui();
    ~MercuryGui()override;
    Shared& shared(){return state_;}
    bool isOpen()const{return active_;}
    bool isUdp()const{return active_&&activeMode_=="UDP"&&worker_->isLinkUp();}
    double fullScale()const{return vref_->value()*(adcRange_->currentIndex()==0?1.0:2.0);}
    void sendCommand(Byte src,const Bytes&payload);
    void sendPrepared(const Bytes&packet);
    void open(){
        if(active_)close();
        activeMode_=mode_->currentText();active_=true;
        const QString ip=ip_->text();const quint16 port=quint16(port_->value());
        const quint16 local=quint16(localPort_->value());
        if(activeMode_=="UDP")
            QMetaObject::invokeMethod(worker_,[w=worker_,ip,port,local](){w->openUdp(ip,port,local);},Qt::QueuedConnection);
        else
            QMetaObject::invokeMethod(worker_,[w=worker_,ip,port](){w->openTcp(ip,port);},Qt::QueuedConnection);
    }
    void close(){
        active_=false;
        QMetaObject::invokeMethod(worker_,[w=worker_](){w->close();},Qt::BlockingQueuedConnection);
    }
};

AdcPage::AdcPage(MercuryGui*owner,Shared&shared,int source,QWidget*parent)
    :QWidget(parent),owner_(owner),source_(source),shared_(shared){
    auto*main=new QVBoxLayout(this);
    auto*options=new QGroupBox("ADC channel-pair enable mask");
    auto*g=new QGridLayout(options);
    for(int i=0;i<6;++i){
        auto*box=new QCheckBox(QString("Pair %1: CH%2 + CH%3").arg(i+1).arg(i+1).arg(i+7));
        pairs_[std::size_t(i)]=box;
        g->addWidget(box,i/3,i%3);
        connect(box,&QCheckBox::toggled,this,[this](){setCombo();});
    }
    main->addWidget(options);
    auto*bar=new QHBoxLayout;
    bar->addWidget(btn("Send ADC command",this,[this](){sendCommand();}));
    bar->addWidget(btn("Activate all",this,[this](){for(auto*b:pairs_)b->setChecked(true);}));
    bar->addWidget(btn("Deactivate all",this,[this](){for(auto*b:pairs_)b->setChecked(false);}));
    bar->addWidget(btn("Open grid plot",this,[this](){openGrid();}));
    bar->addWidget(btn("Clear plots",this,[this](){clearCapture();}));
    bar->addWidget(lbl("Channel:"));
    channel_=new QComboBox;bar->addWidget(channel_);
    bar->addWidget(btn("Open selected",this,[this](){
        if(channel_->currentData().isValid())openSingle(channel_->currentData().toInt(),true);
    }));
    bar->addStretch();main->addLayout(bar);
    status_=lbl(QString("ADC%1: No telemetry yet.").arg(source_-4));
    status_->setWordWrap(true);main->addWidget(status_);
    auto*note=lbl("Full history uses timestamped peak-preserving blocks; recent view shows real received samples. "
                   "Drag plot to zoom; double-click to fit.");
    note->setWordWrap(true);main->addWidget(note);
    log_=new QPlainTextEdit;initLog(log_);log_->setMinimumHeight(180);
    main->addWidget(log_,1);setCombo();
}
void AdcPage::setCombo(){
    lastDrawFrames_=std::numeric_limits<std::uint64_t>::max();
    int previous=channel_->currentData().toInt();auto s=selected();
    channel_->clear();for(auto ch:s)channel_->addItem(QString("CH%1").arg(ch),ch);
    int i=channel_->findData(previous);if(i>=0)channel_->setCurrentIndex(i);
}
void AdcPage::sendCommand(){
    try{
        Byte wire=0;
        for(int i=0;i<6;++i)if(pairs_[std::size_t(i)]->isChecked())wire|=Byte(0x80u>>i);
        owner_->sendCommand(Byte(source_),Bytes{wire});
        log(QString("[%1] ADC pair mask=%2 | wire DATA=%3").arg(stamp(),sh(mask()),sh(wire)));}
    catch(const std::exception&e){errorBox(this,errorString(e));}
}
void AdcPage::openGrid(){
    if(gridWindow_){gridWindow_->raise();gridWindow_->activateWindow();return;}
    auto*dialog=new QDialog(this);dialog->setAttribute(Qt::WA_DeleteOnClose);
    dialog->setWindowTitle(QString("ADC%1 - full-history grid").arg(source_-4));
    dialog->resize(1310,850);
    auto*layout=new QVBoxLayout(dialog);
    auto*bar=new QHBoxLayout;
    bar->addWidget(lbl("Blue: received ADC | Time uses FPGA timestamps"));bar->addStretch();
    bar->addWidget(btn("Fit all / Live",dialog,[this](){for(auto*p:gridPlots_)if(p)p->resetZoom();}));
    layout->addLayout(bar);
    auto*scroll=new QScrollArea;scroll->setWidgetResizable(true);
    auto*body=new QWidget;auto*g=new QGridLayout(body);g->setSpacing(7);
    gridPlots_.clear();
    for(int ch=1;ch<=12;++ch){
        auto*plot=new TraceWidget(body);plot->setMinimumSize(385,220);
        g->addWidget(plot,(ch-1)/3,(ch-1)%3);
        gridPlots_.push_back(plot);
    }
    scroll->setWidget(body);layout->addWidget(scroll,1);
    gridWindow_=dialog;
    connect(dialog,&QObject::destroyed,this,[this](){gridWindow_=nullptr;gridPlots_.clear();});
    dialog->show();lastDrawFrames_=std::numeric_limits<std::uint64_t>::max();refresh(owner_->fullScale());
}
void AdcPage::openSingle(int ch,bool restart){
    if(ch<1||ch>12)return;
    auto& item=singles_[std::size_t(ch-1)];
    if(item.dialog){
        item.dialog->raise();item.dialog->activateWindow();
    } else {
        auto*dlg=new QDialog(this);dlg->setAttribute(Qt::WA_DeleteOnClose);
        dlg->setWindowTitle(QString("ADC%1 CH%2 - native C++ live trace").arg(source_-4).arg(ch));
        dlg->resize(1080,670);
        auto*v=new QVBoxLayout(dlg);
        auto*h=new QHBoxLayout;
        h->addWidget(lbl("View:"));
        auto*choice=new QComboBox;choice->addItems({"Recent live / AD7266 model","Full retained history"});
        h->addWidget(choice);h->addStretch();
        h->addWidget(btn("Restart capture",dlg,[this,ch](){openSingle(ch,true);}));
        auto*plot=new TraceWidget(dlg);plot->setMinimumSize(950,490);
        h->addWidget(btn("Fit all / Live",dlg,[plot](){plot->resetZoom();}));
        v->addLayout(h);v->addWidget(plot,1);
        v->addWidget(lbl("Mouse: drag a rectangle to zoom; scroll to zoom; double-click to return to live."));
        item.dialog=dlg;item.channel=ch;item.view=choice;item.plots={plot};
        connect(choice,QOverload<int>::of(&QComboBox::currentIndexChanged),this,[this](){
            lastDrawFrames_=std::numeric_limits<std::uint64_t>::max();refresh(owner_->fullScale());
        });
        connect(dlg,&QObject::destroyed,this,[this,ch](){
            auto& p=singles_[std::size_t(ch-1)];p.dialog=nullptr;p.plots.clear();p.view=nullptr;
        });
        dlg->show();
    }
    if(restart){
        const auto count=shared_.adc[std::size_t(source_-5)].stats().counts[std::size_t(ch-1)];
        item.baseline=count?count-1:0;
        if(item.view)item.view->setCurrentIndex(0);
        if(!selected().empty()&&owner_->isOpen())sendCommand();
    }
    lastDrawFrames_=std::numeric_limits<std::uint64_t>::max();refresh(owner_->fullScale());
}
std::vector<std::uint16_t> AdcPage::reference(int ch,const std::vector<Sample>&raw)const{
    if(source_!=7||raw.empty())return {};
    int active=std::max(1,int(bitCount(unsigned(mask()))));
    int step=active%64;
    int offset=(ch<=6?(ch-1)*3:(ch-7)*3+16)%64;
    int bestPhase=0;std::uint64_t bestErr=std::numeric_limits<std::uint64_t>::max();
    for(int p=0;p<64;++p){
        std::uint64_t err=0;
        for(std::size_t i=0;i<raw.size();++i){
            int d=int(raw[i].code)-int(Adc3Lut[std::size_t((p+offset+int(i)*step)%64)]);
            err+=std::uint64_t(d*d);
        }
        if(err<bestErr){bestErr=err;bestPhase=p;}
    }
    std::vector<std::uint16_t>model;model.reserve(raw.size());
    for(std::size_t i=0;i<raw.size();++i)
        model.push_back(Adc3Lut[std::size_t((bestPhase+offset+int(i)*step)%64)]);
    return model;
}
void AdcPage::refresh(double fullScale){
    const auto stats=shared_.adc[std::size_t(source_-5)].stats();
    if(stats.frames!=lastCount_){
        lastCount_=stats.frames;
        QString latest;
        for(int i=0;i<12;++i)if(stats.counts[std::size_t(i)]){
            if(!latest.isEmpty())latest+=" ";
            latest+=QString("CH%1=%2").arg(i+1).arg(sh(stats.lastCodes[std::size_t(i)],3));
        }
        status_->setText(QString("ADC%1 | TM V%2 | frames=%3 | FPGA t=%4 s | seq gaps=%5 | dup=%6 | %7")
            .arg(source_-4).arg(stats.version).arg(qulonglong(stats.frames)).arg(stats.lastTimeSeconds,0,'f',6)
            .arg(qulonglong(stats.seqGaps)).arg(qulonglong(stats.duplicates)).arg(latest));
        if(lastVersion_!=stats.version){lastVersion_=stats.version;
            if(stats.frames)log(QString("[%1] TM V%2 received; 32-bit FPGA time for V3 / 16-bit for V1.").arg(stamp()).arg(stats.version));
        }
    }
    if(stats.frames==lastDrawFrames_ && fullScale==lastFullScale_)return;
    lastDrawFrames_=stats.frames;lastFullScale_=fullScale;
    const auto active=selected();
    if(gridWindow_ && gridWindow_->isVisible() && gridPlots_.size()==12){
        for(int ch=1;ch<=12;++ch){
            auto*p=gridPlots_[std::size_t(ch-1)];
            bool visible=std::find(active.begin(),active.end(),ch)!=active.end();
            p->setVisible(visible);
            if(visible){auto data=shared_.adc[std::size_t(source_-5)].full(ch);
                p->setTrace(data,fullScale,QString("ADC%1 CH%2 | full time | points=%3")
                    .arg(source_-4).arg(ch).arg(qulonglong(data.size())));
            }
        }
    }
    for(int ch=1;ch<=12;++ch){
        auto&item=singles_[std::size_t(ch-1)];if(!item.dialog||!item.dialog->isVisible()||item.plots.empty())continue;
        bool isRecent=item.view&&item.view->currentIndex()==0;
        std::vector<Sample> data;
        if(isRecent){
            const int pairs=std::max(1,int(bitCount(unsigned(mask()))));
            const int cycle=(source_==7)?64/std::gcd(64,pairs):64;
            auto limit=std::size_t((source_==7)?cycle*4:256);
            auto total=stats.counts[std::size_t(ch-1)];
            if(item.baseline>total)item.baseline=0;
            data=shared_.adc[std::size_t(source_-5)].recent(ch,limit,item.baseline);
        }else data=shared_.adc[std::size_t(source_-5)].full(ch);
        auto model=isRecent?reference(ch,data):std::vector<std::uint16_t>{};
        QString title=QString("ADC%1 CH%2 | %3 | shown=%4 | total=%5")
            .arg(source_-4).arg(ch).arg(isRecent?"recent":"full history").arg(qulonglong(data.size()))
            .arg(qulonglong(stats.counts[std::size_t(ch-1)]));
        if(!data.empty())title+=QString(" | latest=%1 V").arg(data.back().code*fullScale/4096.0,0,'f',5);
        item.plots[0]->setTrace(data,fullScale,title,model);
    }
}

MercuryGui::MercuryGui():worker_(new NetworkWorker(state_)){
    setWindowTitle("Mercury XU5 PE1 TC/TM - Native C++17 / Qt 6 - Timestamp V3");
    resize(1450,930);
    worker_->moveToThread(&networkThread_);
    connect(&networkThread_,&QThread::finished,worker_,&QObject::deleteLater);
    networkThread_.start();clock_.start();
    buildInterface();
    auto*refresh=new QTimer(this);refresh->setInterval(50);
    connect(refresh,&QTimer::timeout,this,[this](){refreshPlots();});refresh->start();
    auto*logs=new QTimer(this);logs->setInterval(150);
    connect(logs,&QTimer::timeout,this,[this](){flushLogs();});logs->start();
    auto*stats=new QTimer(this);stats->setInterval(500);
    connect(stats,&QTimer::timeout,this,[this](){refreshCounters();});stats->start();
    autoPollTimer_=new QTimer(this);autoPollTimer_->setInterval(500);
    connect(autoPollTimer_,&QTimer::timeout,this,[this](){pollHpu();});autoPollTimer_->start();
}
MercuryGui::~MercuryGui(){
    if(networkThread_.isRunning()){
        close();networkThread_.quit();networkThread_.wait();
    }
}
void MercuryGui::buildInterface(){
    auto*central=new QWidget;setCentralWidget(central);
    auto*main=new QVBoxLayout(central);
    auto*top=new QHBoxLayout;
    mode_=new QComboBox;mode_->addItems({"UDP","TCP"});top->addWidget(lbl("Mode"));top->addWidget(mode_);
    ip_=new QLineEdit("192.168.1.50");ip_->setMaximumWidth(155);
    top->addWidget(lbl("Board IP"));top->addWidget(ip_);
    port_=new QSpinBox;port_->setRange(1,65535);port_->setValue(5001);
    top->addWidget(lbl("Port"));top->addWidget(port_);
    localPort_=new QSpinBox;localPort_->setRange(0,65535);localPort_->setValue(0);
    top->addWidget(lbl("Local UDP port"));top->addWidget(localPort_);
    top->addWidget(btn("Connect / Open",this,[this](){open();}));
    top->addWidget(btn("Disconnect",this,[this](){close();}));
    connection_=lbl("Disconnected");top->addWidget(connection_,1);
    main->addLayout(top);
    auto*options=new QHBoxLayout;
    logTelemetry_=new QCheckBox("Log every telemetry frame");
    logRaw_=new QCheckBox("Log raw RX packets");
    options->addWidget(logTelemetry_);options->addWidget(logRaw_);
    auto verbose=[this](){
        bool tm=logTelemetry_->isChecked(),rx=logRaw_->isChecked();
        QMetaObject::invokeMethod(worker_,[w=worker_,tm,rx](){w->setVerbose(tm,rx);},Qt::QueuedConnection);
    };
    connect(logTelemetry_,&QCheckBox::toggled,this,[verbose](){verbose();});
    connect(logRaw_,&QCheckBox::toggled,this,[verbose](){verbose();});
    options->addSpacing(13);options->addWidget(lbl("ADC VREF (V)"));
    vref_=dbl(2.5,0.001,100,4);options->addWidget(vref_);
    adcRange_=new QComboBox;adcRange_->addItems({"0..VREF (RANGE=0)","0..2*VREF (RANGE=1)"});
    options->addWidget(adcRange_);
    options->addWidget(lbl("V3 tick (us)"));
    tick_=dbl(1.0,0.001,1000.0,3);
    tick_->setToolTip("The FPGA V3 tick currently equals 1 us. Changing the value affects NEW samples only; clear plots first.");
    options->addWidget(tick_);options->addStretch();main->addLayout(options);
    connect(tick_,QOverload<double>::of(&QDoubleSpinBox::valueChanged),this,[this](double us){
        state_.tickSeconds.store(us*1e-6);
    });
    counters_=lbl("TX=0 RX=0 ...");tmStatus_=lbl("RX TM: waiting; V3 TIME32 / 1 us; V1 TIME16 / 1 ms");
    main->addWidget(counters_);main->addWidget(tmStatus_);
    tabs_=new QTabWidget;
    tabs_->addTab(buildSpike(),"Spikeulike");tabs_->addTab(buildDac(),"DAC");
    tabs_->addTab(buildAdc(),"ADC");tabs_->addTab(buildHpu(),"HPU Core");
    main->addWidget(tabs_,1);
    statusBar()->showMessage("C++ native receive/parse; GUI plots at 50 ms target; double-click plots to reset zoom");
}
QWidget* MercuryGui::buildSpike(){
    auto*tab=new QWidget;auto*layout=new QVBoxLayout(tab);
    auto*hint=lbl("Spikeulike source 0x00 | V1: 1..256 bytes | V2: 257..422 bytes (3371 bits, last 5 ignored by HDL)");
    layout->addWidget(hint);
    spikeInput_=new QPlainTextEdit;spikeInput_->setPlaceholderText("HEX payload bytes (do not include V1/V2 headers)");
    layout->addWidget(spikeInput_,2);
    auto*buttons=new QHBoxLayout;
    buttons->addWidget(btn("Send",tab,[this](){
        try{auto payload=parseHex(spikeInput_->toPlainText().toStdString());sendCommand(0,payload);}
        catch(const std::exception&e){errorBox(this,errorString(e));}
    }));
    buttons->addWidget(btn("Packet preview",tab,[this](){
        try{auto payload=parseHex(spikeInput_->toPlainText().toStdString());
            auto packet=buildCommand(0,seq_,payload);addLine(spikeLog_,"PREVIEW: "+fromHex(packet));}
        catch(const std::exception&e){errorBox(this,errorString(e));}
    }));
    buttons->addWidget(btn("Load HEX text file",tab,[this](){
        QString path=QFileDialog::getOpenFileName(this,"Spike HEX file",{},"Text (*.txt *.hex);;All files (*)");
        if(path.isEmpty())return;
        QFile f(path);if(!f.open(QIODevice::ReadOnly)){errorBox(this,"Cannot open selected file");return;}
        spikeInput_->setPlainText(QString::fromUtf8(f.readAll()));
    }));
    buttons->addWidget(btn("Clear",tab,[this](){spikeInput_->clear();}));
    buttons->addStretch();layout->addLayout(buttons);
    spikeLog_=new QPlainTextEdit;initLog(spikeLog_);layout->addWidget(lbl("Spike TX echo / telemetry"));layout->addWidget(spikeLog_,1);
    return tab;
}
QWidget* MercuryGui::buildDac(){
    auto*tab=new QWidget;auto*layout=new QVBoxLayout(tab);
    auto*settings=new QGroupBox("DAC8568 waveform: one cycle stored in FPGA, then replayed by hardware");
    auto*grid=new QGridLayout(settings);
    int col=0,row=0;
    dacChip_=new QComboBox;dacChip_->addItems({"DAC1","DAC2","DAC3","DAC4"});
    grid->addWidget(lbl("Physical DAC"),row,col++);grid->addWidget(dacChip_,row,col++);
    dacChan_=new QComboBox;dacChan_->addItems({"A","B","C","D","E","F","G","H"});
    grid->addWidget(lbl("Channel"),row,col++);grid->addWidget(dacChan_,row,col++);
    dacWave_=new QComboBox;dacWave_->addItems({"Sine","Cosine","Pulse","Triangle"});
    grid->addWidget(lbl("Waveform"),row,col++);grid->addWidget(dacWave_,row,col++);
    dacFreq_=dbl(1000,0.000001,1e8,6);dacFreq_->setSingleStep(100);
    grid->addWidget(lbl("Frequency (Hz)"),row,col++);grid->addWidget(dacFreq_,row,col++);
    col=0;++row;
    dacAmp_=dbl(1.0,0,100,4);grid->addWidget(lbl("Amplitude (V)"),row,col++);grid->addWidget(dacAmp_,row,col++);
    dacSamples_=new QSpinBox;dacSamples_->setRange(1,125);dacSamples_->setValue(125);
    grid->addWidget(lbl("Samples / cycle"),row,col++);grid->addWidget(dacSamples_,row,col++);
    dacClock_=dbl(100000000.0,1,1e10,0);
    grid->addWidget(lbl("FPGA clock (Hz)"),row,col++);grid->addWidget(dacClock_,row,col++);
    dacScale_=dbl(1.8,0.001,100,4);
    grid->addWidget(lbl("DAC full-scale (V)"),row,col++);grid->addWidget(dacScale_,row,col++);
    col=0;++row;
    dacDuty_=dbl(50,0.01,99.99,2);
    grid->addWidget(lbl("Pulse duty (%)"),row,col++);grid->addWidget(dacDuty_,row,col++);
    dacAuto_=new QCheckBox("AUTO_START");dacAuto_->setChecked(true);
    dacArm_=new QCheckBox("ARM_ONLY");dacReset_=new QCheckBox("RESET_PHASE");dacReset_->setChecked(true);
    grid->addWidget(dacAuto_,row,col++);grid->addWidget(dacArm_,row,col++);grid->addWidget(dacReset_,row,col++);
    connect(dacAuto_,&QCheckBox::toggled,this,[this](bool on){if(on)dacArm_->setChecked(false);});
    connect(dacArm_,&QCheckBox::toggled,this,[this](bool on){if(on)dacAuto_->setChecked(false);});
    layout->addWidget(settings);
    auto*actions=new QHBoxLayout;
    actions->addWidget(btn("Generate / refresh",tab,[this](){refreshDac();}));
    actions->addWidget(btn("Send waveform to FPGA",tab,[this](){sendDacLoad();}));
    actions->addWidget(btn("Copy command HEX",tab,[this](){refreshDac();
        QApplication::clipboard()->setText(dacPreview_->toPlainText().section('\n',0,0));}));
    actions->addStretch();layout->addLayout(actions);
    dacPlot_=new TraceWidget;dacPlot_->setMinimumHeight(210);layout->addWidget(dacPlot_,2);
    auto*commands=new QGroupBox("Start/stop controls");auto*bc=new QVBoxLayout(commands);auto*masks=new QHBoxLayout;
    for(int i=0;i<8;++i){
        dacMask_[std::size_t(i)]=new QCheckBox(QString(QChar('A'+i)));
        masks->addWidget(dacMask_[std::size_t(i)]);
    }
    masks->addWidget(btn("Select all",tab,[this](){for(auto*b:dacMask_)b->setChecked(true);}));
    masks->addWidget(btn("Clear mask",tab,[this](){for(auto*b:dacMask_)b->setChecked(false);}));
    masks->addStretch();bc->addLayout(masks);
    auto*controls=new QHBoxLayout;
    controls->addWidget(btn("Stop / zero selected",tab,[this](){sendDacControl(0x08+dacChan_->currentIndex());}));
    controls->addWidget(btn("Start selected mask",tab,[this](){sendDacControl(0x10);}));
    controls->addWidget(btn("Stop / zero mask",tab,[this](){sendDacControl(0x11);}));
    controls->addStretch();bc->addLayout(controls);layout->addWidget(commands);
    dacPreview_=new QPlainTextEdit;initLog(dacPreview_);dacPreview_->setMaximumHeight(90);
    dacPreview_->setPlaceholderText("Packet preview");layout->addWidget(dacPreview_);
    dacLog_=new QPlainTextEdit;initLog(dacLog_);dacLog_->setMaximumHeight(110);
    layout->addWidget(dacLog_);
    auto refreshed=[this](){refreshDac();};
    connect(dacFreq_,QOverload<double>::of(&QDoubleSpinBox::valueChanged),this,[refreshed](double){refreshed();});
    connect(dacSamples_,QOverload<int>::of(&QSpinBox::valueChanged),this,[refreshed](int){refreshed();});
    connect(dacWave_,QOverload<int>::of(&QComboBox::currentIndexChanged),this,[refreshed](int){refreshed();});
    connect(dacAmp_,QOverload<double>::of(&QDoubleSpinBox::valueChanged),this,[refreshed](double){refreshed();});
    connect(dacScale_,QOverload<double>::of(&QDoubleSpinBox::valueChanged),this,[refreshed](double){refreshed();});
    connect(dacChan_,QOverload<int>::of(&QComboBox::currentIndexChanged),this,[refreshed](int){refreshed();});
    connect(dacChip_,QOverload<int>::of(&QComboBox::currentIndexChanged),this,[refreshed](int){refreshed();});
    connect(dacClock_,QOverload<double>::of(&QDoubleSpinBox::valueChanged),this,[refreshed](double){refreshed();});
    refreshDac();return tab;
}
QWidget* MercuryGui::buildAdc(){
    auto*widget=new QWidget;auto*layout=new QVBoxLayout(widget);
    adcTabs_=new QTabWidget;layout->addWidget(adcTabs_);
    for(int i=0;i<4;++i){
        adcPages_[std::size_t(i)]=new AdcPage(this,state_,i+5);
        adcTabs_->addTab(adcPages_[std::size_t(i)],QString("ADC%1").arg(i+1));
    }
    return widget;
}
QWidget* MercuryGui::buildHpu(){
    auto*outer=new QWidget;auto*layout=new QVBoxLayout(outer);
    hpuStatus_=lbl("HPU Core source=0x09 | UDP control only | no events yet");layout->addWidget(hpuStatus_);
    auto*pages=new QTabWidget;layout->addWidget(pages,1);
    auto*control=new QWidget;auto*cv=new QVBoxLayout(control);
    auto*buttons=new QHBoxLayout;
    buttons->addWidget(btn("Apply AUX PAER + OnlyEventsRx",control,[this](){
        if(!isUdp()){errorBox(this,"HPU control requires UDP connection");return;}
        sendHpuWrite(0x48,0x02000100,0x0f);sendHpuWrite(0x60,0x00000002,0x0f);
        sendHpuWrite(0x00,0x00002002,0x0f);
    }));
    buttons->addWidget(btn("Read project registers",control,[this](){
        for(auto a:HpuPollRegisters)sendHpuRead(Byte(a));
    }));
    buttons->addWidget(btn("Read all",control,[this](){
        for(auto r:HpuRegisters)sendHpuRead(Byte(r.addr));
    }));
    autoPoll_=new QCheckBox("Auto status");autoPoll_->setChecked(true);buttons->addWidget(autoPoll_);
    autoPollMs_=new QSpinBox;autoPollMs_->setRange(100,60000);autoPollMs_->setValue(500);buttons->addWidget(autoPollMs_);
    buttons->addWidget(lbl("ms"));buttons->addStretch();cv->addLayout(buttons);
    auto*raw=new QHBoxLayout;
    raw->addWidget(lbl("Address"));hpuAddress_=new QLineEdit("0x00");hpuAddress_->setMaximumWidth(90);raw->addWidget(hpuAddress_);
    raw->addWidget(lbl("Write data"));hpuValue_=new QLineEdit("0x00000000");hpuValue_->setMaximumWidth(155);raw->addWidget(hpuValue_);
    raw->addWidget(lbl("WSTRB"));hpuStrobe_=new QLineEdit("0x0F");hpuStrobe_->setMaximumWidth(70);raw->addWidget(hpuStrobe_);
    auto parseField=[](QLineEdit*e,std::uint32_t maximum){
        bool ok=false;auto value=e->text().toUInt(&ok,0);
        if(!ok||value>maximum)throw std::invalid_argument("Invalid HPU hexadecimal field");
        return value;
    };
    raw->addWidget(btn("Read",control,[this,parseField](){
        try{sendHpuRead(Byte(parseField(hpuAddress_,255)));}
        catch(const std::exception&e){errorBox(this,errorString(e));}
    }));
    raw->addWidget(btn("Write",control,[this,parseField](){
        try{sendHpuWrite(Byte(parseField(hpuAddress_,255)),parseField(hpuValue_,0xffffffffu),Byte(parseField(hpuStrobe_,15)));}
        catch(const std::exception&e){errorBox(this,errorString(e));}
    }));
    raw->addStretch();cv->addLayout(raw);
    regsTable_=new QTableWidget(int(HpuRegisters.size()),6);
    regsTable_->setHorizontalHeaderLabels({"Address","Register","Access","Value","AXI","Description"});
    regsTable_->setEditTriggers(QAbstractItemView::NoEditTriggers);
    regsTable_->horizontalHeader()->setSectionResizeMode(5,QHeaderView::Stretch);
    regsTable_->setColumnWidth(1,175);regsTable_->setColumnWidth(3,125);regsTable_->setColumnWidth(5,450);
    for(int i=0;i<int(HpuRegisters.size());++i){
        auto r=HpuRegisters[std::size_t(i)];
        QStringList cells{sh(r.addr),r.name,r.access,"-","-",r.description};
        for(int c=0;c<6;++c)regsTable_->setItem(i,c,new QTableWidgetItem(cells[c]));
    }
    connect(regsTable_,&QTableWidget::cellClicked,this,[this](int row,int){
        if(row>=0&&row<int(HpuRegisters.size())){
            hpuAddress_->setText(sh(HpuRegisters[std::size_t(row)].addr));
            if(regsTable_->item(row,3)&&regsTable_->item(row,3)->text()!="-")
                hpuValue_->setText(regsTable_->item(row,3)->text());
        }
    });
    cv->addWidget(regsTable_,1);pages->addTab(control,"Registers and configuration");
    auto*events=new QWidget;auto*ev=new QVBoxLayout(events);
    auto*actions=new QHBoxLayout;
    actions->addWidget(btn("Clear events",events,[this](){state_.hpu.clear();eventTable_->setRowCount(0);}));
    actions->addWidget(btn("Save CSV",events,[this](){
        auto path=QFileDialog::getSaveFileName(this,"Save HPU events",{},"CSV (*.csv)");if(path.isEmpty())return;
        QFile file(path);if(!file.open(QIODevice::WriteOnly|QIODevice::Text)){errorBox(this,"Cannot write CSV");return;}
        QTextStream out(&file);
        out<<"index,host_unix_time,tel_seq,fpga_time,raw_event_hex,address9,version,fpga_time_seconds\n";
        for(const auto&e:state_.hpu.all())
            out<<e.index<<','<<QString::number(e.hostSeconds,'f',9)<<','<<int(e.seq)<<','<<e.fpgaTime<<','
               <<sh(e.rawEvent,8)<<','<<e.address<<','<<int(e.version)<<','<<QString::number(e.fpgaSeconds,'f',9)<<'\n';
    }));
    actions->addWidget(btn("Save binary raw32",events,[this](){
        auto path=QFileDialog::getSaveFileName(this,"Save HPU raw events",{},"Binary (*.bin)");if(path.isEmpty())return;
        QFile file(path);if(!file.open(QIODevice::WriteOnly)){errorBox(this,"Cannot write binary file");return;}
        for(const auto&e:state_.hpu.all()){
            QByteArray word;word.append(char(e.rawEvent>>24));word.append(char(e.rawEvent>>16));
            word.append(char(e.rawEvent>>8));word.append(char(e.rawEvent));file.write(word);
        }
    }));actions->addStretch();ev->addLayout(actions);
    eventTable_=new QTableWidget(0,5);
    eventTable_->setHorizontalHeaderLabels({"#","Host time","TEL_SEQ","RAW32","ADDR9"});
    eventTable_->setEditTriggers(QAbstractItemView::NoEditTriggers);
    eventTable_->horizontalHeader()->setStretchLastSection(true);
    eventTable_->setMinimumHeight(220);ev->addWidget(eventTable_,1);
    auto*chartRow=new QHBoxLayout;
    hpuHistogram_=new TraceWidget;hpuRate_=new TraceWidget;
    hpuHistogram_->setMinimumHeight(240);hpuRate_->setMinimumHeight(240);
    chartRow->addWidget(hpuHistogram_);chartRow->addWidget(hpuRate_);ev->addLayout(chartRow);
    pages->addTab(events,"Events and plots");
    auto*logTab=new QWidget;auto*lg=new QVBoxLayout(logTab);
    hpuLog_=new QPlainTextEdit;initLog(hpuLog_);lg->addWidget(hpuLog_);
    lg->addWidget(btn("Clear log",logTab,[this](){hpuLog_->clear();}));
    pages->addTab(logTab,"Raw log");
    connect(autoPollMs_,QOverload<int>::of(&QSpinBox::valueChanged),this,[this](int ms){if(autoPollTimer_)autoPollTimer_->setInterval(ms);});
    return outer;
}

void MercuryGui::refreshDac(){
    try{
        auto n=dacSamples_->value();double clock=dacClock_->value(),f=dacFreq_->value();
        auto period=dacPeriod(clock,f,n);
        auto samples=dacWaveform(static_cast<Wave>(dacWave_->currentIndex()),n,
                                 dacAmp_->value(),dacScale_->value(),dacDuty_->value());
        Byte flags=Byte((dacAuto_->isChecked()?1:0)|(dacArm_->isChecked()?2:0)|(dacReset_->isChecked()?4:0));
        auto packet=dacLoad(seq_,Byte(dacChip_->currentIndex()+1),Byte(dacChan_->currentIndex()),flags,period,samples);
        dacPreview_->setPlainText(fromHex(packet)+QString("\nPERIOD=%1 ticks | actual f=%2 Hz | sample rate=%3 samples/s | samples=%4 | flags=%5")
                                  .arg(period).arg(clock/double(period*n),0,'g',10)
                                  .arg(clock/double(period),0,'g',10).arg(n).arg(sh(flags)));
        std::vector<QPointF>plotSamples;plotSamples.reserve(samples.size());
        for(int i=0;i<n;++i)plotSamples.emplace_back(double(i)*period/clock,
            double(samples[std::size_t(i)])*dacScale_->value()/65535.0);
        dacPlot_->setXY(std::move(plotSamples),dacScale_->value(),QString("%1 DAC%2 channel %3 | actual f=%4 Hz")
            .arg(dacWave_->currentText()).arg(dacChip_->currentIndex()+1).arg(dacChan_->currentText())
            .arg(clock/double(period*n),0,'g',10),"Waveform time (s)");
    }catch(const std::exception&e){
        dacPreview_->setPlainText("Invalid DAC settings: "+errorString(e));dacPlot_->clear();
    }
}
void MercuryGui::sendDacLoad(){
    try{
        auto period=dacPeriod(dacClock_->value(),dacFreq_->value(),dacSamples_->value());
        auto samples=dacWaveform(static_cast<Wave>(dacWave_->currentIndex()),dacSamples_->value(),
                                 dacAmp_->value(),dacScale_->value(),dacDuty_->value());
        Byte flags=Byte((dacAuto_->isChecked()?1:0)|(dacArm_->isChecked()?2:0)|(dacReset_->isChecked()?4:0));
        auto packet=dacLoad(seq_,Byte(dacChip_->currentIndex()+1),Byte(dacChan_->currentIndex()),flags,period,samples);
        sendPrepared(packet);addLine(dacLog_,QString("[%1] Queued DAC%2 %3 %4 | %5 samples")
            .arg(stamp()).arg(dacChip_->currentIndex()+1).arg(dacChan_->currentText())
            .arg(dacWave_->currentText()).arg(qulonglong(samples.size())));
    }catch(const std::exception&e){errorBox(this,errorString(e));}
}
void MercuryGui::sendDacControl(int cmd){
    try{
        Bytes payload;
        if(cmd>=8&&cmd<=15)payload={Byte(cmd)};
        else{
            Byte mask=0;for(int i=0;i<8;++i)if(dacMask_[std::size_t(i)]->isChecked())mask|=Byte(1<<i);
            if(mask==0)throw std::invalid_argument("Select at least one DAC channel in the mask");
            payload={Byte(cmd),mask};
        }
        sendCommand(Byte(dacChip_->currentIndex()+1),payload);
        addLine(dacLog_,QString("[%1] DAC control payload: %2").arg(stamp(),fromHex(payload)));
    }catch(const std::exception&e){errorBox(this,errorString(e));}
}
void MercuryGui::sendPrepared(const Bytes&packet){
    if(!active_ || !worker_->isLinkUp())throw std::runtime_error("Ethernet connection is not open yet");
    QByteArray data(reinterpret_cast<const char*>(packet.data()),int(packet.size()));
    QMetaObject::invokeMethod(worker_,[w=worker_,data](){w->sendPacket(data);},Qt::QueuedConnection);
    state_.logs.push({-1,QString("[%1] TX queued %2 bytes: %3").arg(stamp()).arg(qulonglong(packet.size()))
        .arg(QString::fromStdString(hex(packet,300))).toStdString()});
    seq_=Byte((seq_+1)&255);
}
void MercuryGui::sendCommand(Byte source,const Bytes&payload){
    sendPrepared(buildCommand(source,seq_,payload));
}
void MercuryGui::sendHpuRead(Byte addr){
    if(!isUdp()){errorBox(this,"HPU control requires an open UDP connection");return;}
    try{sendPrepared(hpuRead(seq_,addr));}
    catch(const std::exception&e){errorBox(this,errorString(e));}
}
void MercuryGui::sendHpuWrite(Byte addr,std::uint32_t data,Byte strobe){
    if(!isUdp()){errorBox(this,"HPU control requires an open UDP connection");return;}
    try{sendPrepared(hpuWrite(seq_,addr,data,strobe));}
    catch(const std::exception&e){errorBox(this,errorString(e));}
}
void MercuryGui::pollHpu(){
    if(!autoPoll_ || !autoPoll_->isChecked() || !isUdp())return;
    int index=pollIndex_++%int(HpuPollRegisters.size());
    sendHpuRead(Byte(HpuPollRegisters[std::size_t(index)]));
}
void MercuryGui::refreshHpu(){
    for(int i=0;i<int(HpuRegisters.size());++i){
        auto address=Byte(HpuRegisters[std::size_t(i)].addr);
        std::uint32_t value=0;int axi=0;
        if(state_.hpu.getRegister(address,value,axi)){
            regsTable_->item(i,3)->setText(sh(value,8));
            regsTable_->item(i,4)->setText(sh(axi));
        }
    }
    static std::uint64_t lastEvents=std::numeric_limits<std::uint64_t>::max();
    auto total=state_.hpu.count();
    hpuStatus_->setText(QString("HPU Core source=0x09 | total events=%1 | buffered last 250000 | 9-bit address").arg(qulonglong(total)));
    if(total==lastEvents)return;
    lastEvents=total;
    auto recent=state_.hpu.recent(150);
    eventTable_->setUpdatesEnabled(false);
    eventTable_->setRowCount(int(recent.size()));
    for(int i=0;i<int(recent.size());++i){
        const auto&e=recent[std::size_t(i)];
        QDateTime dt=QDateTime::fromMSecsSinceEpoch(qint64(e.hostSeconds*1000));
        QStringList cells{QString::number(e.index),dt.toString("HH:mm:ss.zzz"),
                           sh(e.seq),sh(e.rawEvent,8),sh(e.address,3)};
        for(int j=0;j<5;++j){
            auto* item=eventTable_->item(i,j);
            if(!item){item=new QTableWidgetItem;eventTable_->setItem(i,j,item);}
            item->setText(cells[j]);
        }
    }
    eventTable_->setUpdatesEnabled(true);
    // Plot only small derived summaries rather than redrawing 250000 event records.
    auto hist=state_.hpu.histogram();
    std::uint64_t maxHist=1;
    for(auto v:hist)maxHist=std::max(maxHist,v);
    std::vector<QPointF>histPoints;histPoints.reserve(514);
    for(std::size_t i=0;i<hist.size();++i)histPoints.emplace_back(double(i),double(hist[i]));
    hpuHistogram_->setXY(histPoints,double(maxHist)*1.05,"HPU 9-bit address counts","Event address (0..511)");
    const double now=QDateTime::currentMSecsSinceEpoch()/1000.0;
    constexpr int bins=60;constexpr double window=30.0,dt=0.5;
    auto bin=state_.hpu.rates(now);
    int maxRate=1;std::vector<QPointF>rates;rates.reserve(bins);
    for(int i=0;i<bins;++i){int rate=bin[std::size_t(i)];
        maxRate=std::max(maxRate,rate);rates.emplace_back(-window+(i+0.5)*dt,rate);
    }
    hpuRate_->setXY(rates,double(maxRate)*1.05,"HPU host event rate (events/s)","Time relative to now (s)");
}
void MercuryGui::flushLogs(){
    for(auto& r:state_.logs.drain(250)){
        auto line=QString::fromStdString(r.text);
        if(r.source==0)addLine(spikeLog_,line);
        else if(r.source>=1&&r.source<=4)addLine(dacLog_,line);
        else if(r.source>=5&&r.source<=8)adcPages_[std::size_t(r.source-5)]->log(line);
        else addLine(hpuLog_,line);
    }
}
void MercuryGui::refreshCounters(){
    QString status=worker_->status();connection_->setText(status);
    const auto rx = state_.rx.load();
    const auto elapsed = clock_.elapsed();
    double dt=std::max(double(elapsed-lastCounterMs_)*1e-3,1e-6);
    double rate=double(rx-lastRx_)/dt;lastRx_=rx;lastCounterMs_=elapsed;
    std::uint64_t gaps=0,duplicates=0;
    for(const auto& adc:state_.adc){auto st=adc.stats();gaps+=st.seqGaps;duplicates+=st.duplicates;}
    counters_->setText(QString("TX=%1 | RX=%2 (~%3 packets/s) | parse errors=%4 | filtered=%5 | "
        "ADC per-source seq skips=%6 | duplicates=%7 | log overflow=%8 | socket errors=%9 | next seq=%10")
        .arg(qulonglong(state_.tx.load())).arg(qulonglong(rx)).arg(rate,0,'f',0).arg(qulonglong(state_.parseErrors.load()))
        .arg(qulonglong(state_.filtered.load())).arg(qulonglong(gaps)).arg(qulonglong(duplicates))
        .arg(qulonglong(state_.logs.dropped())).arg(qulonglong(state_.socketErrors.load())).arg(sh(seq_)));
    tmStatus_->setText(QString("Telemetry V%1 | V3 raw FPGA 32-bit timestamp tick=%2 us (1 us resolution by default). "
                              "Acquisition does not depend on the UI paint rate.")
        .arg(state_.lastTmVersion.load()).arg(tick_->value()));
    refreshHpu();
}
void MercuryGui::refreshPlots(){
    for(auto*p:adcPages_)if(p)p->refresh(fullScale());
}
} // namespace

int main(int argc,char**argv){
    QApplication app(argc,argv);
    QApplication::setApplicationName("Mercury XU5 Native TC/TM");
    MercuryGui window;
    window.show();
    return app.exec();
}
