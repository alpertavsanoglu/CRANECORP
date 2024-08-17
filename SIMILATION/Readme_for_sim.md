https://drive.google.com/drive/u/0/folders/1-PHkvvI4QLXAx4mf9EXLoKwyEBU_YFUs

makefile ın içindeki "UE4_SOURCE" kısmına unreal engine source dosyasının pathini giriniz. Ardından make dediğinizde compile edicek ve runlıcak(Eğer run yapmazsa make run komutunu kullanabilirsiniz.)
Unreal engine 4.27-5.1 versiyonlarında compile edilmiştir.

windows içinden wsl ile çalıştırmak için makefile ı aşağıdaki ile değiştirin:

all: build compile_cpp run

UE4_SOURCE = UnrealEngine-4.27

PROJECT_NAME = Real_Time

PROJECT_PATH = .

CONFIGURATION = Development

TARGET_PLATFORM = Win64

PARALLEL_JOBS = 8

CPP_FILE = write_txt.cpp

CPP_OUTPUT = write_txt

HTTPLIB_INCLUDE = cpp-httplib-master


build:

	cd $(UE4_SOURCE) && ./Engine/Build/BatchFiles/RunUAT.bat BuildCookRun -project=$(PROJECT_PATH)/$(PROJECT_NAME).uproject -noP4 -platform=$(TARGET_PLATFORM) -clientconfig=$(CONFIGURATION) -serverconfig=$(CONFIGURATION) -cook -build -stage -pak -archive -archivedirectory=$(PROJECT_PATH)/Build

compile_cpp:

	g++ -std=c++11 -pthread -I$(HTTPLIB_INCLUDE) $(CPP_FILE) -o $(CPP_OUTPUT)

run:

	./$(CPP_OUTPUT) & $(PROJECT_PATH)/Saved/StagedBuilds/WindowsNoEditor/$(PROJECT_NAME).exe

