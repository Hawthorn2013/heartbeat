heartbeat:heartbeat.o
	echo "You are in heartbeat"
	$(CC) $(LDFLAGS) heartbeat.o -o heartbeat
heartbeat.o:heartbeat.c
	$(CC) $(CFLAGS) -c heartbeat.c

clean:
	rm *.o heartbeat
