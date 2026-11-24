// Synthetic decoder/capture benchmark. This is NOT a measurement of Ethernet throughput.
#include "protocol.hpp"
#include "capture.hpp"
#include <chrono>
#include <iostream>
using namespace xu5;
int main(int argc,char**argv){
    std::uint64_t n=500000;
    if(argc>1){ try{n=std::stoull(argv[1]);}catch(...){} }
    n=std::min<std::uint64_t>(n,20000000);
    Bytes tm{3,0,0,0,0,0,7,2,1,0x0a,0xbc};
    Frame frame;AdcCapture cap;
    auto t0=std::chrono::steady_clock::now();
    for(std::uint64_t i=0;i<n;++i){
        tm[1]=Byte(i);auto time=std::uint32_t(i);
        tm[2]=Byte(time>>24);tm[3]=Byte(time>>16);tm[4]=Byte(time>>8);tm[5]=Byte(time);
        if(!parseDatagram(tm.data(),tm.size(),frame))return 1;
        cap.ingest(frame,1e-6);
    }
    auto t1=std::chrono::steady_clock::now();
    double s=std::chrono::duration<double>(t1-t0).count();
    auto stats=cap.stats();
    std::cout<<"Synthetic core ONLY: "<<n<<" V3 ADC frames in "<<s
             <<" s ("<<(n/s)<<" frames/s); captured="<<stats.frames
             <<" retained channel samples="<<cap.rawForExport(1).size()
             <<". No UDP, Qt, plotting, disk I/O, or FPGA involved.\n";
}
