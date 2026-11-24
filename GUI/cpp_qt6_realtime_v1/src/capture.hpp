#pragma once
#include "protocol.hpp"
#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <deque>
#include <mutex>
#include <string>
#include <vector>

namespace xu5 {
struct Sample {
    double t=0.0;
    std::uint16_t code=0;
    std::uint64_t index=0;
};
struct Envelope {
    Sample lo,hi;
    std::uint64_t begin=0,end=0;
};
struct ChannelCapture {
    static constexpr std::size_t limit=250000;
    static constexpr std::size_t block=128;
    std::deque<Sample> raw;
    std::deque<Envelope> summary;
    Envelope building;
    std::size_t buildingCount=0;
    std::uint64_t nextIndex=0;
    void clear(){raw.clear();summary.clear();buildingCount=0;nextIndex=0;}
    void add(double t,std::uint16_t code) {
        Sample s{t,code,nextIndex++};
        raw.push_back(s);
        if(raw.size()>limit) raw.pop_front();
        if(!buildingCount) building={s,s,s.index,s.index};
        else {
            if(s.code<building.lo.code) building.lo=s;
            if(s.code>building.hi.code) building.hi=s;
            building.end=s.index;
        }
        if(++buildingCount==block){summary.push_back(building);buildingCount=0;}
        while(!summary.empty() && !raw.empty() && summary.front().begin<raw.front().index)
            summary.pop_front();
    }
    std::vector<Sample> recent(std::size_t maxPoints,std::uint64_t minIndex=0) const {
        std::vector<Sample> result;
        const std::size_t n=std::min(maxPoints,raw.size());result.reserve(n);
        auto it=raw.rbegin();
        for(std::size_t i=0;i<n;++i,++it) {
            if(it->index<minIndex)break;
            result.push_back(*it);
        }
        std::reverse(result.begin(),result.end()); return result;
    }
    std::vector<Sample> full(std::size_t rawThreshold=1800) const {
        std::vector<Sample> out;
        if(raw.size()<=rawThreshold) {out.assign(raw.begin(),raw.end());return out;}
        if(raw.empty())return out;
        // Peak-preserving immutable blocks: O(history / 128) rather than O(history).
        out.reserve(summary.size()*2+260);
        const auto earliest=raw.front().index;
        const auto latest=raw.back().index;
        std::uint64_t left=earliest;
        for(const auto& b:summary) {
            if(b.begin<left || b.end>latest)continue;
            // A small partial leading block is copied from the live ring.
            while(left<b.begin && left-earliest<raw.size()) {
                out.push_back(raw[std::size_t(left-earliest)]);++left;
            }
            if(b.lo.index<b.hi.index){out.push_back(b.lo);out.push_back(b.hi);}
            else if(b.hi.index<b.lo.index){out.push_back(b.hi);out.push_back(b.lo);}
            else out.push_back(b.lo);
            left=b.end+1;
        }
        while(left<=latest && left-earliest<raw.size()) {
            out.push_back(raw[std::size_t(left-earliest)]);++left;
        }
        return out;
    }
};
struct CaptureStats {
    std::uint64_t frames=0, seqGaps=0, duplicates=0, outOfOrder=0;
    int version=0;std::uint32_t lastTime=0;
    double lastTimeSeconds=0;
    std::array<std::uint64_t,Channels> counts{};
    std::array<std::uint16_t,Channels> lastCodes{};
};
class AdcCapture {
    mutable std::mutex mutex_;
    std::array<ChannelCapture,Channels> channels_;
    CaptureStats stats_;
    bool hasSeq_=false, hasTime_=false;
    Byte seq_=0;
    std::uint32_t previousTime_=0;
    std::uint64_t epoch_=0;
public:
    void clear(){
        std::lock_guard<std::mutex> g(mutex_);
        for(auto& c:channels_)c.clear();
        stats_={};hasSeq_=hasTime_=false;epoch_=0;
    }
    void ingest(const Frame& f,double v3TickSeconds) {
        if(f.kind!=Kind::Telemetry || f.source<5 || f.source>8)return;
        std::lock_guard<std::mutex> g(mutex_);
        if(stats_.version && stats_.version!=f.version){
            for(auto& c:channels_)c.clear();
            stats_={};hasSeq_=hasTime_=false;epoch_=0;
        }
        stats_.version=f.version;
        if(hasSeq_){
            int delta=(int(f.seq)-int(seq_)+256)%256;
            if(delta==0)++stats_.duplicates;
            else if(delta>1&&delta<=127)stats_.seqGaps+=std::uint64_t(delta-1);
            else if(delta>127)++stats_.outOfOrder;
        }
        seq_=f.seq;hasSeq_=true;
        auto modulo=(f.version==V3) ? (1ULL<<32) : (1ULL<<16);
        auto raw=std::uint32_t(f.timestamp)&std::uint32_t(modulo-1);
        if(hasTime_ && raw<previousTime_ && std::uint64_t(previousTime_-raw)>modulo/2)
            epoch_+=modulo;
        previousTime_=raw;hasTime_=true;
        const auto ticks=epoch_+raw;
        const double t=double(ticks)*((f.version==V3)?v3TickSeconds:1e-3);
        ++stats_.frames;stats_.lastTime=raw;stats_.lastTimeSeconds=t;
        for(std::size_t i=0;i+2<f.payload.size();i+=3) {
            Byte ch=f.payload[i];
            if(ch<1 || ch>Channels)continue;
            auto code=std::uint16_t(be16(f.payload.data()+i+1)&0x0FFF);
            auto slot=std::size_t(ch-1);
            channels_[slot].add(t,code);
            ++stats_.counts[slot];stats_.lastCodes[slot]=code;
        }
    }
    CaptureStats stats()const{std::lock_guard<std::mutex> g(mutex_);return stats_;}
    std::vector<Sample> recent(int ch,std::size_t n,std::uint64_t minIndex=0)const{
        if(ch<1||ch>Channels)return {};
        std::lock_guard<std::mutex>g(mutex_);
        return channels_[std::size_t(ch-1)].recent(n,minIndex);
    }
    std::vector<Sample> full(int ch)const {
        if(ch<1||ch>Channels)return {};
        std::lock_guard<std::mutex>g(mutex_);
        return channels_[std::size_t(ch-1)].full();
    }
    std::vector<Sample> rawForExport(int ch)const {
        if(ch<1||ch>Channels)return {};
        std::lock_guard<std::mutex>g(mutex_);
        auto& q=channels_[std::size_t(ch-1)].raw;
        return {q.begin(),q.end()};
    }
};
struct HpuEvent {
    double hostSeconds=0,fpgaSeconds=0;
    std::uint32_t fpgaTime=0, rawEvent=0;
    std::uint64_t index=0;
    Byte seq=0, version=0;
    int address=0;
};
class HpuCapture {
    mutable std::mutex mutex_;
    std::deque<HpuEvent> records_;
    std::deque<std::pair<std::int64_t,std::uint64_t>> rateBins_;
    std::array<std::uint64_t,512> histogram_{};
    std::array<std::uint32_t,256> registers_{};
    std::array<int,256> axi_{};
    std::array<bool,256> present_{};
    std::uint64_t total_=0;
    std::uint64_t epoch_=0;
    std::uint32_t lastRaw_=0;
    int lastVersion_=0;
    bool hasTime_=false;
public:
    void clear(){std::lock_guard<std::mutex>g(mutex_);records_.clear();rateBins_.clear();histogram_.fill(0);total_=0;hasTime_=false;epoch_=0;lastVersion_=0;}
    void ingest(const Frame& f,double v3Tick) {
        if(f.kind!=Kind::Telemetry || f.source!=HPU || f.payload.empty())return;
        std::lock_guard<std::mutex>g(mutex_);
        if(lastVersion_!=f.version){hasTime_=false;epoch_=0;lastVersion_=f.version;}
        auto modulo=(f.version==V3)?(1ULL<<32):(1ULL<<16);
        auto raw=f.timestamp&std::uint32_t(modulo-1);
        if(hasTime_&&raw<lastRaw_&&std::uint64_t(lastRaw_-raw)>modulo/2)epoch_+=modulo;
        lastRaw_=raw;hasTime_=true;
        if(f.payload[0]==0x40 && f.payload.size()>=5) {
            auto word=be32(f.payload.data()+1);
            HpuEvent e;
            e.hostSeconds=std::chrono::duration<double>(std::chrono::system_clock::now().time_since_epoch()).count();
            e.fpgaTime=raw;e.fpgaSeconds=double(epoch_+raw)*((f.version==V3)?v3Tick:1e-3);
            e.rawEvent=word;e.index=++total_;e.seq=f.seq;e.version=f.version;e.address=int(word&0x1ff);
            if(records_.size()>=250000)records_.pop_front();
            records_.push_back(e);++histogram_[std::size_t(e.address)];
            const auto bucket=std::int64_t(std::floor(e.hostSeconds*2.0));
            if(!rateBins_.empty() && rateBins_.back().first==bucket)++rateBins_.back().second;
            else rateBins_.push_back({bucket,1});
            while(rateBins_.size()>64)rateBins_.pop_front();
        } else if(f.payload[0]==0x82&&f.payload.size()>=8){
            Byte a=f.payload[1];registers_[a]=be32(f.payload.data()+4);axi_[a]=f.payload[2];present_[a]=true;
        } else if(f.payload[0]==0x81&&f.payload.size()>=4){
            Byte a=f.payload[1];axi_[a]=f.payload[2];
        }
    }
    std::uint64_t count()const{std::lock_guard<std::mutex>g(mutex_);return total_;}
    std::vector<HpuEvent> recent(std::size_t n)const{
        std::lock_guard<std::mutex>g(mutex_);n=std::min(n,records_.size());return {records_.end()-static_cast<std::ptrdiff_t>(n),records_.end()};
    }
    std::array<int,60> rates(double nowSeconds)const{
        std::lock_guard<std::mutex>g(mutex_);
        std::array<int,60>result{};
        const auto latest=std::int64_t(std::floor(nowSeconds*2.0));
        for(const auto&entry:rateBins_){
            const auto index=entry.first-(latest-59);
            if(index>=0&&index<60)result[std::size_t(index)]=int(std::min<std::uint64_t>(entry.second*2,2000000000));
        }
        return result;
    }
    std::vector<HpuEvent> since(double seconds)const{
        std::lock_guard<std::mutex>g(mutex_);
        auto begin=records_.end();
        while(begin!=records_.begin() && (begin-1)->hostSeconds>=seconds)--begin;
        return {begin,records_.end()};
    }
    std::vector<HpuEvent> all()const{
        std::lock_guard<std::mutex>g(mutex_);return {records_.begin(),records_.end()};
    }
    std::array<std::uint64_t,512> histogram()const{std::lock_guard<std::mutex>g(mutex_);return histogram_;}
    bool getRegister(Byte addr,std::uint32_t&value,int&axi)const{
        std::lock_guard<std::mutex>g(mutex_);if(!present_[addr])return false;
        value=registers_[addr];axi=axi_[addr];return true;
    }
};
struct LogRecord {int source=-1;std::string text;};
class LogQueue {
    mutable std::mutex mutex_;
    std::deque<LogRecord> data_;
    std::uint64_t dropped_=0;
public:
    void push(LogRecord r) {
        std::lock_guard<std::mutex>g(mutex_);
        if(data_.size()>=4000){data_.pop_front();++dropped_;}
        data_.push_back(std::move(r));
    }
    std::vector<LogRecord> drain(std::size_t n=250){
        std::lock_guard<std::mutex>g(mutex_);
        n=std::min(n,data_.size());std::vector<LogRecord>v;v.reserve(n);
        while(n--){v.push_back(std::move(data_.front()));data_.pop_front();}return v;
    }
    std::uint64_t dropped()const{std::lock_guard<std::mutex>g(mutex_);return dropped_;}
};
struct Shared {
    std::array<AdcCapture,4> adc;
    HpuCapture hpu;
    LogQueue logs;
    std::atomic<std::uint64_t> rx{0},tx{0},parseErrors{0},filtered{0},socketErrors{0};
    std::atomic<double> tickSeconds{1e-6};
    std::atomic<int> lastTmVersion{0};
};
} // namespace xu5
