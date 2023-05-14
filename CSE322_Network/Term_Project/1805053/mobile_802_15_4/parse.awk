BEGIN {
    received_packets = 0;
    sent_packets = 0;
    dropped_packets = 0;
    total_delay = 0;
    received_bytes = 0;
    start_time = 1000000;
    start_energy = 0;
    end_time = 0;
    # constants
    header_bytes = 20;
    first_cycle = 1;
}


{
    event = $1;
    time_sec = $2;
    node = $3;
    layer = $4;
    is_end = $5;
    packet_id = $6;
    packet_type = $7;
    packet_bytes = $8;


    sub(/^_*/, "", node);
	sub(/_*$/, "", node);



    # set start time for the first line
    if(start_time > time_sec && time_sec != "-t") {
        start_time = time_sec;
    }


    
    if (event=="N" && start_energy <$7) {
        start_energy = $7;
    }

    if(time_sec != "-t"){
        end_time = time_sec;
    }




    if (layer == "AGT" && packet_type == "tcp") {
        
        if(event == "s") {
            sent_time[packet_id] = time_sec;
            sent_packets += 1;
        }

        else if(event == "r") {
            delay = time_sec - sent_time[packet_id];
            if(delay < 0) {     ## sanity check
                print "ERROR";
            }
            total_delay += delay;


            bytes = (packet_bytes - header_bytes);
            received_bytes_per_node[node] += bytes;
            received_bytes += bytes;

            
            received_packets += 1;
        }
       

    }

    if(event == "N") {
        
        final_energy[$5] = $7;
        
    }

    if (packet_type == "tcp" && event == "D" && is_end != "END") {
        dropped_packets += 1;
    }

}


END {

    # end_time = time_sec;
    simulation_time = end_time - start_time;
    total_energy_consumption = 0;

    num_nodes = 0;
    for (i in final_energy) {
        num_nodes += 1;
        total_energy_consumption += (start_energy - final_energy[i]);
    }
    
    avg_energy_consumption = total_energy_consumption / num_nodes;

    avg_energy_consumption_per_sec = avg_energy_consumption / simulation_time;

    print avg_energy_consumption_per_sec, sent_packets, dropped_packets, received_packets, (received_bytes * 8) / simulation_time, (total_delay / received_packets), (received_packets / sent_packets), (dropped_packets / sent_packets);
    
    print "average energy consumption per sec", avg_energy_consumption_per_sec;
    print "sent packets", sent_packets;
    print "dropped packets", dropped_packets;
    print "received packets", received_packets;
    print "throughput", (received_bytes * 8) / simulation_time;
    print "average delay", (total_delay / received_packets);
    print "packet delivery ratio", (received_packets / sent_packets);
    print "packet drop ratio", (dropped_packets / sent_packets);
    print "simulation time", simulation_time;

    
    print "node_id ------ throughput";
    
    for (i = 0; i <= num_nodes; i++) {
        if (received_bytes_per_node[i] != 0)
            print i,"------------", received_bytes_per_node[i]*8/simulation_time;
    }
}

