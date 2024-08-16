#include <pigpio.h>
#include <iostream>
#include <chrono>
#include <thread>
#include <cstdlib>
#include "httplib.h"


using namespace std;

/* PINS X,Y,Z AND MAGNET */
const unsigned int Z_MOTOR_STEP = 24;
const unsigned int Z_MOTOR_DIR = 23;

const unsigned int X_MOTOR_STEP = 21;
const unsigned int X_MOTOR_DIR = 20;

const unsigned int Y_MOTOR_STEP = 8;
const unsigned int Y_MOTOR_DIR = 7;

const unsigned int MAGNET_PIN = 12;

/* MOTORS MULTIPLIER  */
const int X_MULTIPLIER = 791;
const int Y_MULTIPLIER = 784;

// Global position of the motors
int x = 0;
int y = 0;
int z = 0;

/* Functions for the motors to move */
void x_axis(int target);
void y_axis(int target);
void z_axis(int target);

void x_axis(int target){
        int distance = abs(target-x); // Distance that motors need to travel at x axis

        // Set the direction pin
        if(target-x >= 0) {
                gpioWrite(X_MOTOR_DIR, 0);
        } else {
                gpioWrite(X_MOTOR_DIR, 1);
        }
        int millisecond = distance;
        x = target; // Set the global x axis to integer target

        auto start = std::chrono::steady_clock::now();
        while (std::chrono::steady_clock::now() - start < std::chrono::milliseconds(millisecond)) {
                // Toggle step pin on and off with a short delay between toggles
                gpioWrite(X_MOTOR_STEP, 1);
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
                gpioWrite(X_MOTOR_STEP, 0);
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
}

void y_axis(int target){
        int distance = abs(target-y); // Distance that motor need to travel at y axis

        // Set the direction pin
        if(target-y >= 0) {
                gpioWrite(Y_MOTOR_DIR, 1);
        } else {
                gpioWrite(Y_MOTOR_DIR, 0);
        }
        int millisecond = distance;
        y = target; // Set the global y axis to integer target
        auto start = std::chrono::steady_clock::now();
        while (std::chrono::steady_clock::now() - start < std::chrono::milliseconds(millisecond)) {
                // Toggle step pin on and off with a short delay between toggles
                gpioWrite(Y_MOTOR_STEP, 1);
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
                gpioWrite(Y_MOTOR_STEP, 0);
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
}

void z_axis(int target){
        int distance = abs(target-z); // Distance that motor need to travel at z axis

        // Set the direction pin
        if(target-z >= 0) {
                gpioWrite(Z_MOTOR_DIR, 1);
        } else {
                gpioWrite(Z_MOTOR_DIR, 0);
        }
        int millisecond = distance;
        z = target; // Set the gloal y axis to integer target

        auto start = std::chrono::steady_clock::now();
        while (std::chrono::steady_clock::now() - start < std::chrono::milliseconds(millisecond)) {
                // Toggle step pin on and off with a short delay between toggles
                gpioWrite(Z_MOTOR_STEP, 1);
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
                gpioWrite(Z_MOTOR_STEP, 0);
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
}

void controlElectromagnet(bool on) {
    if (on) {
        gpioWrite(MAGNET_PIN, 1);  // Turn on electromagnet
    } else {
        gpioWrite(MAGNET_PIN, 0);  // Turn off electromagnet
    }
}

int main() {
        // Initialise the Pigpio
        if (gpioInitialise() < 0) {
                cerr << "Failed to initialize pigpio" << std::endl;
                return 1;
        }


        /* Set the Pins of motors and electro magnet */
        gpioSetMode(Z_MOTOR_STEP, PI_OUTPUT);
        gpioSetMode(Z_MOTOR_DIR, PI_OUTPUT);
        gpioSetMode(Y_MOTOR_STEP, PI_OUTPUT);
        gpioSetMode(Y_MOTOR_DIR, PI_OUTPUT);
        gpioSetMode(X_MOTOR_STEP, PI_OUTPUT);
        gpioSetMode(X_MOTOR_DIR, PI_OUTPUT);
        gpioSetMode(MAGNET_PIN, PI_OUTPUT);


        /* Http server cominication  */
        httplib::Server svr;
        svr.Post("/move", [](const httplib::Request &req, httplib::Response &res) {
                // Take the pickup and dropoff cordinates from mobile app
                int pickup_x = stoi(req.get_param_value("pickup_x"));
                int pickup_y = stoi(req.get_param_value("pickup_y"));
                int dropoff_x = stoi(req.get_param_value("drop_x"));
                int dropoff_y = stoi(req.get_param_value("drop_y"));

                cout << "Pickup: " << pickup_x << "-" << pickup_y << endl;
                cout << "Dropoff: " << dropoff_x << "-" << dropoff_y << endl;

                // Protection for the coardinates
                if((pickup_x <= 5 && pickup_x >= 0) && (pickup_y <= 5 && pickup_y >= 0) && (dropoff_x <= 5 && dropoff_x >= 0) && (dropoff_y <= 5 && dropoff_y >= 0)) {
                        x_axis(pickup_x * X_MULTIPLIER);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        y_axis(pickup_y * Y_MULTIPLIER);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        z_axis(2000);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        controlElectromagnet(true);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        z_axis(0);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        x_axis(dropoff_x * X_MULTIPLIER);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        y_axis(dropoff_y * Y_MULTIPLIER);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        z_axis(2000);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        controlElectromagnet(false);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        z_axis(0);
                        std::this_thread::sleep_for(std::chrono::milliseconds(100));

                        /* Move back to 0-0 */
                        //x_axis(0);
                        //std::this_thread::sleep_for(std::chrono::milliseconds(100));
                        //y_axis(0);
                        } else {
                                cout << "INVALID RANGE!\n";
                        }

                        res.set_content("Motors moved", "text/plain");
                });

        cout << "Server Started" << endl;
        svr.listen("0.0.0.0", 8080);

        gpioTerminate();
        return 0;
}