if [ "$#" -eq 2 ] 
then
  	input=$1;
    dir_name=$2;
else
    echo ""
    echo "******************************************"
	echo "Please Specify the PATH of config file and output file";
    echo "An example is:"
    echo "./gen_topcpp.sh ../../config_files/input.cfg ."
    echo "******************************************"
    echo ""
    exit
fi

if [ -f ./${dir_name}/aie/mm_top.cpp ]
then
    echo ""
    echo "******************************************"
    echo "File ./${dir_name}/aie/mm_top.cpp exists." 
    echo "******************************************"
    echo ""
    exit;
fi

for ((n=1;n<=22;n++));
do
	read -r line
	if (( ${n} == 2 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		data_type="${Value[0]}"; 
	elif (( ${n} == 4 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		kernel_type="${Value[0]}";
    elif (( ${n} == 9 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		NUM_PACK_IN="${Value[0]}";
	elif (( ${n} == 10 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		NUM_PACK_OUT="${Value[0]}";
    elif (( ${n} == 11 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		A="${Value[0]}";
    elif (( ${n} == 12 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		B="${Value[0]}";
 	elif (( ${n} == 13 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		C="${Value[0]}";
    elif (( ${n} == 14 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		R_BRO="${Value[0]}";
    elif (( ${n} == 15 ))
	then
		IFS=':' read -ra Key <<< "$line";
		value_temp="${Key[1]}"; 
		unset IFS
		IFS=';' read -ra Value <<< "$value_temp";
		C_BRO="${Value[0]}";
 	fi
done < "$input"

let AIE_NUM=${A}*${B}*${C};

if [ ${B} == 4 ]
then
	let left_aie=400-${AIE_NUM};
elif [ ${B} == 3 ]
then
	if [ ${AIE_NUM} -gt 300 ]
	then
		let left_aie=$(((50%${C})/2*16));
	else	
		let left_aie=400-${AIE_NUM}/3*4;
	fi
fi
let start_pos=${left_aie}/16;


let port_row_in=${AIE_NUM}/${NUM_PACK_IN}/${R_BRO};
let port_col_in=${C}*${B}*${A}/${NUM_PACK_IN}/${C_BRO};
let port_in=${port_row_in}+${port_col_in};
let port_out=${A}*${C}/${NUM_PACK_OUT};

mkdir -p ${dir_name}/aie
if [ ${B} == 4 ] || [ ${B} == 3 ]
then

let NUM_INSTANCES=${A}*${C};
echo \
"#include \"mm_top.h\"
using namespace adf;
#define COL_OFFSET ${start_pos}
#define ROW_OFFSET 0

">> ./${dir_name}/aie/mm_top.cpp;

for ((i=0;i<${port_row_in};i++));
do  
    echo \
    "PLIO *in_r${i}  = new PLIO(\"in_r${i}\",  adf::plio_128_bits, \"data/input0.txt\", 250);">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${port_col_in};i++));
do  
    echo \
    "PLIO *in_c${i}  = new PLIO(\"in_c${i}\",  adf::plio_128_bits, \"data/input1.txt\", 250);">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${port_out};i++));
do  
    echo \
    "PLIO *out_${i} = new PLIO(\"out_${i}\", adf::plio_128_bits, \"./data/output_${i}.txt\", 250);">> ./${dir_name}/aie/mm_top.cpp;
done



echo \
"
mm_x${NUM_INSTANCES}_x${B}_graph<COL_OFFSET,ROW_OFFSET> myGraph;

simulation::platform<${port_in},${port_out}> platform(">> ./${dir_name}/aie/mm_top.cpp;

for ((i=0;i<${port_row_in};i++));
do  
    echo \
    "in_r${i},">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${port_col_in};i++));
do  
    echo \
    "in_c${i},">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${port_out}-1;i++));
do  
    echo \
    "out_${i},">> ./${dir_name}/aie/mm_top.cpp;
done

echo \
"out_$((${port_out}-1))
);                           
">> ./${dir_name}/aie/mm_top.cpp;

for ((i=0;i<${port_row_in};i++));
do  
    echo \
    "connect<> netir${i}(platform.src[${i}], myGraph.in_row[${i}]);">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${port_col_in};i++));
do  
    let col_num=${i}+${port_row_in};
    echo \
    "connect<> netic${i}(platform.src[${col_num}], myGraph.in_col[${i}]);">> ./${dir_name}/aie/mm_top.cpp;
done

for ((i=0;i<${port_out};i++));
do  
    echo \
    "connect<> neto${i}(myGraph.out[${i}],  platform.sink[${i}]);">> ./${dir_name}/aie/mm_top.cpp;
done

echo \
"
#ifdef __AIESIM__

int main(void) {
  myGraph.init();
  myGraph.run(8);
  myGraph.end();
  return 0;
}

#endif
">> ./${dir_name}/aie/mm_top.cpp;

fi