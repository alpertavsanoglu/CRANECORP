TARGET = cranecorp
SRC = cranecorp.cpp
LIBS = -lpigpio -pthread

$(TARGET): $(SRC)
	g++ -o $@ $^ $(LIBS)

clean:
	rm -f $(TARGET)
