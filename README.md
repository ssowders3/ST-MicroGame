# ST-MicroGame
Implementation of game on ST Microcontroller in ARM assembly

When the game starts, the user to configure how many players will join the game by pressing the pushbutton on the ST Micro board. One press in the initial 10 seconds means one player; two presses in the initial 10 seconds means two players. This game can support from 1 game player up to 2 game players. During this state, both of the green and blue LED will flash in an on-off pattern with an interval of approximately one second.

	If player number < 1
	Exit the game with Blue LED on and Green LED off

	If player number = 1 

Flash Green LED and Blue LED alternatively for 6 rounds. Both of the LEDs remain lit for 1/(n+1) seconds , where n is the number of points that have been scored. n = 0 at the beginning when nothing is pressed. If the pushbutton is pressed while the Blue LED is lit, a point is scored. (One round means the Green LED lit for 1/(n+1)   seconds and Blue LED lit for 1/(n+1) seconds)

After 6 rounds, the Green LED will flash n_player1 times with approximately one second of time interval and then exit the game with Blue LED and Green LED both on.


	If player number = 2

Flash Green LED for approximately one second for 5 times to indicate that it is the turn for player 1. Then Flash Green LED and Blue LED alternatively for 6 rounds. Both of the LEDs remain lit for 1/(n_player1+1) seconds , where n_player1 is the number of points that have been scored. n_player1 = 0 at the beginning when nothing is pressed. If the pushbutton is pressed while the Blue LED is lit, a point is scored. (One round means the Green LED lit for 1/(n_player1+1)   seconds and Blue LED lit for 1/(n_player1+1) seconds)

Then Flash Blue LED for approximately one second for 5 times to indicate that it is the turn for player 2. Then Flash Green LED and Blue LED alternatively for 6 rounds. Both of the LEDs remain lit for 1/(n_player2+1) seconds, where n is the number of points that have been scored. n_player2 = 0 at the beginning when nothing is pressed. If the pushbutton is pressed while the Blue LED is lit, a point is scored. (One round means the Green LED lit for 1/(n_player2+1)   seconds and Blue LED lit for 1/(n_player2+1) seconds)

After each player play for 6 rounds, the Green LED will flash n_player1 times with approximately one second of time interval and then flash the Blue LED n_player2 with approximately one second of timer interval exit the game with Blue LED on and Green LED both on.


	If player number > 2
Exit the game with Green LED on and Blue LED off