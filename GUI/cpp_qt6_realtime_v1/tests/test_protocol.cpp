#include "protocol.hpp"
#include "capture.hpp"
#include <cassert>
#include <iostream>
#include <cstring>
using namespace xu5;
int main(){
    auto adc=adcCommand(0x07,0x2A,0x3F);
    assert((adc==Bytes{1,0x2A,7,0,0xFC}));
    assert((adcCommand(7,0,1)==Bytes{1,0,7,0,0x80}));
    assert((adcCommand(7,0,2)==Bytes{1,0,7,0,0x40}));
    assert((adcCommand(7,0,32)==Bytes{1,0,7,0,0x04}));
    auto hread=hpuRead(9,0x48); assert((hread==Bytes{1,9,9,1,2,0x48}));
    auto hwrite=hpuWrite(0x10,0x48,0x02000100);
    assert((hwrite==Bytes{1,0x10,9,7,1,0x48,0x0f,0,2,0,1,0}));
    Bytes spike(422,0xA5);auto spikeFrame=buildCommand(0,12,spike);
    assert(spikeFrame.size()==427 && spikeFrame[0]==2 && spikeFrame[3]==1 && spikeFrame[4]==0xA5);
    auto period=dacPeriod(100000000.0,1000.0,125);assert(period==800);
    auto wave=dacWaveform(Wave::Sine,125,1.0,1.8);
    auto dac=dacLoad(10,1,0,0x05,period,wave);
    assert(dac.size()==260 && dac[3]==255 && dac[4]==0 && dac[5]==5 && dac[6]==0 && dac[7]==0 && dac[8]==3 && dac[9]==0x20);
    assert(Adc3Lut.size()==64 && Adc3Lut[0]==0x800 && Adc3Lut[16]==0xF08 && Adc3Lut[48]==0x0F8 && Adc3Lut[63]==0x750);
    Frame f;
    Bytes tm3{3,0xFE,0,0,0,100,7,2,1,0x0A,0xBC};
    assert(parseDatagram(tm3.data(),tm3.size(),f));
    assert(f.kind==Kind::Telemetry && f.version==3 && f.timestamp==100 && f.source==7 && f.payload.size()==3);
    Bytes tm1{1,0x33,0x12,0x34,0x05,2,7,0x08,0x08};
    assert(parseDatagram(tm1.data(),tm1.size(),f) && f.timestamp==0x1234 && f.source==5);
    assert(!parseDatagram(tm3.data(),tm3.size()-1,f));
    Frame echo;assert(parseDatagram(adc.data(),adc.size(),echo)&&echo.kind==Kind::CommandEcho);
    assert(parseDatagram(spikeFrame.data(),spikeFrame.size(),echo) && echo.version==V2 && echo.payload.size()==422);
    AdcCapture cap;
    assert(parseDatagram(tm3.data(),tm3.size(),f));cap.ingest(f,1e-6);
    auto recent=cap.recent(1,12);assert(recent.size()==1 && recent[0].code==0xABC && std::abs(recent[0].t-100e-6)<1e-10);
    assert(cap.stats().frames==1);
    for(int k=0;k<3000;++k){
        Bytes d{3,Byte(k),Byte((k>>24)&255),Byte((k>>16)&255),Byte((k>>8)&255),Byte(k),7,2,1,Byte((k>>8)&0x0f),Byte(k)};
        assert(parseDatagram(d.data(),d.size(),f)); cap.ingest(f,1e-6);
    }
    assert(cap.stats().counts[0]==3001);
    auto full=cap.full(1);assert(full.size()<130 && !full.empty());
    auto tail=cap.recent(1,4);assert(tail.size()==4);
    cap.clear();assert(cap.stats().frames==0);
    // V3 32-bit FPGA time counter wrap must remain monotonically extended.
    Bytes wrapA{3,1,0xFF,0xFF,0xFF,0xFE,7,2,1,0,1};
    Bytes wrapB{3,2,0,0,0,2,7,2,1,0,2};
    assert(parseDatagram(wrapA.data(),wrapA.size(),f));cap.ingest(f,1e-6);
    assert(parseDatagram(wrapB.data(),wrapB.size(),f));cap.ingest(f,1e-6);
    auto wraps=cap.recent(1,2);assert(wraps.size()==2 && wraps[1].t>wraps[0].t);
    assert(std::abs((wraps[1].t-wraps[0].t)-4e-6)<1e-8);
    // Keep 250k newest received values and retain raw sample codes.
    cap.clear();
    for(int i=0;i<250100;++i){
        Bytes many{3,Byte(i),Byte(i>>24),Byte(i>>16),Byte(i>>8),Byte(i),7,2,1,Byte(i>>8),Byte(i)};
        assert(parseDatagram(many.data(),many.size(),f));cap.ingest(f,1e-6);
    }
    assert(cap.rawForExport(1).size()==250000);
    assert(cap.full(1).size()<5000);
    // HPU raw event word is big-endian and its address uses 9 low bits.
    HpuCapture hpu;
    Bytes he{3,2,0,0,0,5,9,4,0x40,0x0F,0x00,0x01,0xA5};
    assert(parseDatagram(he.data(),he.size(),f));hpu.ingest(f,1e-6);
    assert(hpu.count()==1 && hpu.recent(1)[0].rawEvent==0x0F0001A5u && hpu.recent(1)[0].address==0x1A5);
    auto raw= rebuildRaw(f);assert(raw==he);
    auto hd=hex(adc);assert(parseHex(hd)==adc);
    std::uint64_t errors=0;StreamParser stream;
    auto a=stream.feed(tm3.data(),4,errors);assert(a.empty());
    a=stream.feed(tm3.data()+4,tm3.size()-4,errors);
    assert(a.size()==1 && a[0].kind==Kind::Telemetry);
    std::cout<<"PASS: command compatibility, V1/V2/V3 decode, timestamp, ADC capture, C++ peak envelope, TCP streaming\n";
}
