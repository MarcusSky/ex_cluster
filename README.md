# ExCluster

### Terminal 1
ERL_FLAGS="-name count1@127.0.0.1 -setcookie cookie" NODES="count2@127.0.0.1,count3@127.0.0.1" iex -S mix


### Terminal 2
ERL_FLAGS="-name count2@127.0.0.1 -setcookie cookie" NODES="count1@127.0.0.1,count3@127.0.0.1" iex -S mix


### Terminal 3
ERL_FLAGS="-name count3@127.0.0.1 -setcookie cookie" NODES="count2@127.0.0.1,count1@127.0.0.1" iex -S mix
