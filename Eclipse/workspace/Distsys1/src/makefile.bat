javac *.java
rmic TicTacToeRemoteImp
start rmiregistry 1099
java TicTacToe localhost:1099 yes