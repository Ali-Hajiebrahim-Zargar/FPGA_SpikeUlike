#pragma once
// Mercury XU5 / PE1 application wire protocol. Standard C++17, no Qt dependency.
// Mirrors the Python V4 command formats: V1 TC, V2 Spike extension, V1/V3 TM.
#include <array>
#include <cmath>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>
#include <algorithm>

namespace xu5 {
using Byte = std::uint8_t;
using Bytes = std::vector<Byte>;
constexpr Byte V1=0x01, V2=0x02, V3=0x03, SPIKE=0x00, HPU=0x09;
constexpr std::size_t MaxSpikeBytes=422;
constexpr int Pairs=6, Channels=12, Sources=4;
constexpr std::array<std::pair<int,int>,6> ChannelPairs{{{1,7},{2,8},{3,9},{4,10},{5,11},{6,12}}};
constexpr std::array<std::uint16_t,64> Adc3Lut{{
 0x800,0x8B0,0x95F,0xA0B,0xAB1,0xB51,0xBE8,0xC76,
 0xCF9,0xD6F,0xDD9,0xE33,0xE7F,0xEBA,0xEE5,0xEFF,
 0xF08,0xEFF,0xEE5,0xEBA,0xE7F,0xE33,0xDD9,0xD6F,
 0xCF9,0xC76,0xBE8,0xB51,0xAB1,0xA0B,0x95F,0x8B0,
 0x800,0x750,0x6A1,0x5F5,0x54F,0x4AF,0x418,0x38A,
 0x307,0x291,0x227,0x1CD,0x181,0x146,0x11B,0x101,
 0x0F8,0x101,0x11B,0x146,0x181,0x1CD,0x227,0x291,
 0x307,0x38A,0x418,0x4AF,0x54F,0x5F5,0x6A1,0x750
}};

inline bool sourceValid(Byte b) { return b<=HPU; }
inline std::uint16_t be16(const Byte *p) {
    return (std::uint16_t(p[0])<<8)|std::uint16_t(p[1]);
}
inline std::uint32_t be32(const Byte *p) {
    return (std::uint32_t(p[0])<<24)|(std::uint32_t(p[1])<<16)|
           (std::uint32_t(p[2])<<8)|std::uint32_t(p[3]);
}
inline void put32(Bytes& v, std::uint32_t x) {
    v.push_back(Byte((x>>24)&255)); v.push_back(Byte((x>>16)&255));
    v.push_back(Byte((x>>8)&255)); v.push_back(Byte(x&255));
}
inline Bytes buildCommand(Byte source, Byte seq, const Bytes& payload) {
    if (!sourceValid(source)) throw std::invalid_argument("Invalid source 0x00..0x09");
    if (payload.empty()) throw std::invalid_argument("Payload must not be empty");
    Bytes out;
    if (payload.size() <= 256) {
        out={V1,seq,source,Byte(payload.size()-1)};
    } else {
        if(source!=SPIKE || payload.size()>MaxSpikeBytes)
            throw std::invalid_argument("V2 payload allowed only for Spike (257..422 bytes)");
        const auto len=payload.size()-1;
        out={V2,seq,SPIKE,Byte((len>>8)&255),Byte(len&255)};
    }
    out.insert(out.end(),payload.begin(),payload.end());
    return out;
}
inline Bytes adcCommand(Byte source, Byte seq, Byte pairMask) {
    if(source<5 || source>8) throw std::invalid_argument("ADC source must be 5..8");
    // Pair1 is bit7, Pair2 bit6, ... Pair6 bit2 on the original Python wire protocol.
    Byte onWire=0;
    for(int i=0;i<6;++i)if(pairMask&(1u<<i))onWire|=Byte(0x80u>>i);
    return buildCommand(source,seq,{onWire});
}
inline Bytes hpuRead(Byte seq, Byte addr) { return buildCommand(HPU,seq,{0x02,addr}); }
inline Bytes hpuWrite(Byte seq,Byte addr,std::uint32_t data,Byte strobe=0x0f) {
    Bytes payload{0x01,addr,Byte(strobe&15),0x00};
    put32(payload,data);
    return buildCommand(HPU,seq,payload);
}
inline Bytes dacLoad(Byte seq, Byte source, Byte channel, Byte flags,
                     std::uint32_t period, const std::vector<std::uint16_t>& samples) {
    if(source<1 || source>4 || channel>7 || period==0 || samples.empty() || samples.size()>125)
        throw std::invalid_argument("Invalid DAC settings");
    if((flags&3)==3) throw std::invalid_argument("AUTO_START and ARM_ONLY conflict");
    Bytes payload{channel,flags}; put32(payload,period);
    for(auto code:samples) { payload.push_back(Byte(code>>8)); payload.push_back(Byte(code)); }
    return buildCommand(source,seq,payload);
}
inline std::uint32_t dacPeriod(double clock, double freq, int samplesPerCycle) {
    if(!(std::isfinite(clock)&&std::isfinite(freq)) || clock<=0 || freq<=0 ||
       samplesPerCycle<1 || samplesPerCycle>125)
        throw std::invalid_argument("Invalid DAC clock/frequency/sample count");
    double ideal=clock/(freq*samplesPerCycle);
    if(!std::isfinite(ideal) || ideal<0.5 || ideal>4294967295.49)
        throw std::invalid_argument("DAC period outside unsigned 32-bit range");
    auto ticks=static_cast<std::uint64_t>(std::llround(ideal));
    if(ticks<1 || ticks>4294967295ULL) throw std::invalid_argument("DAC period outside range");
    return static_cast<std::uint32_t>(ticks);
}
enum class Wave {Sine,Cosine,Pulse,Triangle};
inline std::vector<std::uint16_t> dacWaveform(Wave wave,int n,double amplitude,double fullScale,double dutyPct=50) {
    if(n<1 || n>125 || !std::isfinite(amplitude) || !std::isfinite(fullScale) ||
       amplitude<0 || fullScale<=0 || amplitude>fullScale ||
       !std::isfinite(dutyPct) || dutyPct<=0 || dutyPct>=100)
        throw std::invalid_argument("Invalid waveform settings");
    std::vector<std::uint16_t> out; out.reserve(std::size_t(n));
    for(int k=0;k<n;++k) {
        double phase=double(k)/n, norm=0;
        switch(wave) {
            case Wave::Sine: norm=0.5*(1+std::sin(2*3.14159265358979323846*phase)); break;
            case Wave::Cosine: norm=0.5*(1+std::cos(2*3.14159265358979323846*phase)); break;
            case Wave::Pulse: norm=phase < dutyPct/100.0 ? 1.0:0.0; break;
            case Wave::Triangle: norm=1.0-std::abs(2*phase-1); break;
        }
        out.push_back(std::uint16_t(std::clamp(std::llround(amplitude*norm/fullScale*65535.0),0LL,65535LL)));
    }
    return out;
}

enum class Kind {Telemetry,CommandEcho};
struct Frame {
    Kind kind=Kind::Telemetry;
    Byte version=0, seq=0, source=0, lenM1=0;
    std::uint32_t timestamp=0;
    Bytes payload;
    std::size_t total=0;
};
inline std::vector<Frame> frameCandidates(const Byte* bytes, std::size_t count) {
    std::vector<Frame> frames;
    if(!bytes || !count) return frames;
    const Byte v=bytes[0];
    if(v==V3) {
        if(count>=8 && sourceValid(bytes[6])) {
            const std::size_t sz=std::size_t(bytes[7])+1, total=8+sz;
            if(total<=count) frames.push_back({Kind::Telemetry,V3,bytes[1],bytes[6],bytes[7],be32(bytes+2),Bytes(bytes+8,bytes+total),total});
        }
    } else if(v==V2) {
        if(count>=6 && bytes[2]==SPIKE) {
            const std::size_t sz=std::size_t(be16(bytes+3))+1,total=5+sz;
            if(sz>=257 && sz<=MaxSpikeBytes && total<=count)
                frames.push_back({Kind::CommandEcho,V2,bytes[1],SPIKE,0,0,Bytes(bytes+5,bytes+total),total});
        }
    } else if(v==V1) {
        if(count>=4 && sourceValid(bytes[2])) {
            const std::size_t sz=std::size_t(bytes[3])+1,total=4+sz;
            if(total<=count) frames.push_back({Kind::CommandEcho,V1,bytes[1],bytes[2],bytes[3],0,Bytes(bytes+4,bytes+total),total});
        }
        if(count>=6 && sourceValid(bytes[4])) {
            const std::size_t sz=std::size_t(bytes[5])+1,total=6+sz;
            if(total<=count) frames.push_back({Kind::Telemetry,V1,bytes[1],bytes[4],bytes[5],be16(bytes+2),Bytes(bytes+6,bytes+total),total});
        }
    }
    return frames;
}
inline Bytes rebuildRaw(const Frame&f){
    Bytes raw;
    if(f.version==V3 && f.kind==Kind::Telemetry){
        raw={V3,f.seq};put32(raw,f.timestamp);
        raw.push_back(f.source);raw.push_back(f.lenM1);
    }else if(f.version==V2 && f.kind==Kind::CommandEcho){
        const auto size=f.payload.size()-1;
        raw={V2,f.seq,SPIKE,Byte(size>>8),Byte(size&255)};
    }else if(f.version==V1 && f.kind==Kind::Telemetry){
        raw={V1,f.seq,Byte(f.timestamp>>8),Byte(f.timestamp),f.source,f.lenM1};
    }else if(f.version==V1 && f.kind==Kind::CommandEcho){
        raw={V1,f.seq,f.source,f.lenM1};
    }
    raw.insert(raw.end(),f.payload.begin(),f.payload.end());return raw;
}
inline bool parseDatagram(const Byte* bytes,std::size_t count,Frame& out) {
    auto frames=frameCandidates(bytes,count);
    for(const auto& f:frames) if(f.total==count && f.kind==Kind::Telemetry){out=f;return true;}
    for(const auto& f:frames) if(f.total==count){out=f;return true;}
    return false;
}
// TCP has no frame boundary. Follow the Python decoder's "prefer complete TM" rule;
// with ambiguous V1 incomplete data, defer for a possible V1 TM frame.
class StreamParser {
    Bytes buf_;
public:
    void clear(){buf_.clear();}
    std::size_t pending() const{return buf_.size();}
    std::vector<Frame> feed(const Byte* p,std::size_t n,std::uint64_t& parseErrors) {
        if(n>65536 || buf_.size()+n>65536){ buf_.clear();++parseErrors;return {}; }
        buf_.insert(buf_.end(),p,p+n);
        std::vector<Frame> out;
        while(!buf_.empty()) {
            Byte v=buf_[0];
            if(v!=V1&&v!=V2&&v!=V3){buf_.erase(buf_.begin());++parseErrors;continue;}
            if(v==V2 && buf_.size()>=5 &&
                (buf_[2]!=SPIKE || std::size_t(be16(buf_.data()+3))+1>MaxSpikeBytes || std::size_t(be16(buf_.data()+3))+1<257)) {
                buf_.erase(buf_.begin()); ++parseErrors;continue;
            }
            if(v==V3 && buf_.size()>=8 && !sourceValid(buf_[6])) {buf_.erase(buf_.begin());++parseErrors;continue;}
            auto candidates=frameCandidates(buf_.data(),buf_.size());
            if(candidates.empty()) {
                // V1: malformed source after minimum header is evidence to resync.
                if(v==V1 && buf_.size()>=6 && !sourceValid(buf_[2]) && !sourceValid(buf_[4])){
                    buf_.erase(buf_.begin());++parseErrors;continue;
                }
                break;
            }
            const auto it=std::find_if(candidates.begin(),candidates.end(),[](const Frame& f){return f.kind==Kind::Telemetry;});
            Frame f = it==candidates.end()?candidates.front():*it;
            out.push_back(std::move(f));
            buf_.erase(buf_.begin(),buf_.begin()+static_cast<std::ptrdiff_t>(out.back().total));
        }
        return out;
    }
};
inline std::string hex(const Bytes& bytes,std::size_t limit=4096) {
    const char* d="0123456789ABCDEF";
    std::string out; out.reserve(std::min(bytes.size(),limit)*3);
    for(std::size_t i=0;i<std::min(bytes.size(),limit);++i) {
        if(i)out+=' ';
        out+=d[bytes[i]>>4];out+=d[bytes[i]&15];
    }
    if(bytes.size()>limit)out+=" ...";
    return out;
}
inline Bytes parseHex(const std::string& s){
    std::string digits;digits.reserve(s.size());
    for(std::size_t i=0;i<s.size();) {
        if(i+1<s.size() && s[i]=='0' && (s[i+1]=='x'||s[i+1]=='X')){i+=2;continue;}
        unsigned char c=static_cast<unsigned char>(s[i]);
        if(std::isxdigit(c))digits+=char(c);
        else if(!std::isspace(c) && c!=',' && c!=';' && c!='_' && c!='-')
            throw std::invalid_argument("Invalid hexadecimal character");
        ++i;
    }
    if(digits.size()%2) throw std::invalid_argument("Odd number of hexadecimal digits");
    Bytes out;
    for(std::size_t i=0;i<digits.size();i+=2) out.push_back(Byte(std::stoul(digits.substr(i,2),nullptr,16)));
    return out;
}
} // namespace xu5
