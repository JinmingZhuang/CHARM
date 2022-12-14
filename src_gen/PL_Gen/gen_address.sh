if [ "$#" -eq 1 ] 
then
    dir_name=$1;
else
    echo ""
    echo "******************************************"
	echo ""
    echo "PL_Gen/gen_address Missing Arguments"
    echo ""
    echo "******************************************"
    echo ""
    exit
fi


echo \
"
ap_uint<32> generateHeader(unsigned int pktType, unsigned int ID){
#pragma HLS inline
    ap_uint<32> header=0;
    header(4,0)=ID;
    header(11,5)=0;
    header(14,12)=pktType;
    header[15]=0;
    header(20,16)=-1;//source row
    header(27,21)=-1;//source column
    header(30,28)=0;
    header[31]=header(30,0).xor_reduce()?(ap_uint<1>)0:(ap_uint<1>)1;
    return header;
}

unsigned int getPacketId(ap_uint<32> header){
#pragma HLS inline
    ap_uint<32> ID=0;
    ID(4,0)=header(4,0);
    return ID;
}

void address_A_ddr(axis_stream_32& addrA_out,const int TX,const int TY,const int TZ) {
#pragma HLS inline off
    for(int tx=0;tx<TX;tx++){
        for(int tz=0;tz<TZ;tz++){
            for(int ty=0;ty<TY;ty++){
                ap_uint<32> pos;
                for(int j=0;j<K;j++){
                    for(int i=0;i<M/A_PER_TRA;i++){
                    #pragma HLS PIPELINE II = 1
                        pos=i+j*(M/A_PER_TRA)*TX+ty*K*(M/A_PER_TRA)*TX+tx*(M/A_PER_TRA);
                        addrA_out.write(pos);
                    }
                }
            }
        }
    }
}

void loadA_ddr(ap_uint<AXI_WIDTH_A>* ina, axis_stream_32& addrA_in,axis_stream_A& dataA_out,const int TX,const int TY,const int TZ) {
#pragma HLS inline off
    ap_uint<AXI_WIDTH_A> temp_data;
    int bound=boundA*TX*TY*TZ;
    for(int i=0;i<bound;i++){
    #pragma HLS PIPELINE II = 1
        int addr = addrA_in.read();
        temp_data=ina[addr];
        dataA_out.write(temp_data);        
    }
}

void address_B_ddr(axis_stream_32& addrB_out,const int TX,const int TY,const int TZ) {
#pragma HLS inline off    
    for(int tx=0;tx<TX;tx++){
        for(int tz=0;tz<TZ;tz++){
            for(int ty=0;ty<TY;ty++){
                ap_uint<32> pos;
                for(int j=0;j<N;j++){
                    for(int i=0;i<K/B_PER_TRA;i++){
                    #pragma HLS PIPELINE II = 1
                        pos=i+j*(K/B_PER_TRA)*TY+ty*(K/B_PER_TRA)+tz*N*(K/B_PER_TRA)*TY;
                        addrB_out.write(pos);
                    }
                }
            }
        }
    }
}


void loadB_ddr(ap_uint<AXI_WIDTH_B>* inb, axis_stream_32& addrB_in,axis_stream_B& dataB_out,const int TX,const int TY,const int TZ) {
#pragma HLS inline off
    ap_uint<AXI_WIDTH_B> temp_data;
    int bound=boundB*TX*TY*TZ;
    for(int i=0;i<bound;i++){
    #pragma HLS PIPELINE II = 1
        ap_uint<32> addr = addrB_in.read();
        temp_data=inb[addr];
        dataB_out.write(temp_data);
    }  
}

void address_C_ddr(axis_stream_32& addrC_out,const int TX,const int TZ) {
#pragma HLS inline off
    for(int tx=0;tx<TX;tx++){
        for(int tz=0;tz<TZ;tz++){
            ap_uint<32> pos;
            for(int j=0;j<N;j++){
                for(int i=0;i<M/C_PER_TRA;i++){
                #pragma HLS PIPELINE II = 1
                    pos=i+j*(M/C_PER_TRA)*TX+tx*(M/C_PER_TRA)+tz*N*(M/C_PER_TRA)*TX;
                    addrC_out.write(pos);
                }
            }
        }
    }
}

void storeC_ddr(ap_uint<AXI_WIDTH_C>* outc, axis_stream_32& addrC_in,axis_stream_C& dataC_in,const int TX,const int TZ) { 
#pragma HLS inline off
    int bound=boundC*TX*TZ;
    for(int i=0;i<bound;i++){
    #pragma HLS PIPELINE II = 1
        ap_uint<AXI_WIDTH_C> temp_data=dataC_in.read();
        ap_uint<32> addr = addrC_in.read();
        outc[addr]=temp_data;
            
    }
    
}">> ./${dir_name}/kernel/dma.cpp;