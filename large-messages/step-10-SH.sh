openssl rand -hex $((20*1024*1024)) > large-message.bin 
ls -lh large-message.bin