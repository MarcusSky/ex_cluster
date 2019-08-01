# ExCluster

### Terminal 1

`ERL_FLAGS="-name count1@127.0.0.1 -setcookie cookie" NODES="count2@127.0.0.1,count3@127.0.0.1" iex -S mix`

### Terminal 2

`ERL_FLAGS="-name count2@127.0.0.1 -setcookie cookie" NODES="count1@127.0.0.1,count3@127.0.0.1" iex -S mix`

### Terminal 3

`ERL_FLAGS="-name count3@127.0.0.1 -setcookie cookie" NODES="count2@127.0.0.1,count1@127.0.0.1" iex -S mix`

## Docker Swarm

```
$ docker swarm init
$ docker build -t ex_cluster .
$ docker stack deploy -c stack.yml t_ex_cluster
$ docker stack rm t_ex_cluster
```

## Debugging

List all running containers

```
$ docker ps
```

Then start a remote iex

```
$ docker exec -it [container name] bin/ex_cluster remote
```

To see the logs run

```
$ docker logs --follow [container name]
```

## Orders

```elixir
ExCluster.Order.add("Guimas", [1,2,3])
ExCluster.Order.contents("Guimas")
```
