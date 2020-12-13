# State-machine-based-digital-lock
State machine based digital lock using Altera DE1 SoC

Design modules
the design of the top level module				                – DigitalLock.v
the design of the key input processing module		          – KeyProcess.v
the design of the state machine module			              – StateMachine.v
the design of the display of the 7-Segment LEDs		        – SevenSegmentLeds.v

Auto verifying test bench for two sublevel modules and the top level module
Test Bench for the key input processing sublevel module	  – KeyProcess_tb.v
Test Bench for the state machine sublevel module			    – State_Machine_tb.v
Test Bench for the Top level module					              – DigitalLock_tb.v


RTL Flow:
![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/RTL%20Flow.png)

Flow Chart for State Machine:
![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/statemachineflowchart.jpg)

Key Process sublevel module simulation:
![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/Key%20Process.png)

State Machine Sublevel module simulation:
![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/statemachine1.png)

![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/statemachine2.png)

![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/statemachine3.png)

Digital Lock Top Level module simulation:
![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/digitallock1.png)

![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/digitallock2.png)

![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/digitallock3.png)

![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/digitallock4.png)


Pin Assignment:
![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/pin%20assignment1.png)

![Image](https://github.com/koakuma666/State-machine-based-digital-lock/blob/master/DigitakLock%20Images/pin%20assignment2.png)


